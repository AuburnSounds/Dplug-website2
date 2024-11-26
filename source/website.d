import std.stdio;
import std.array;
import std.conv;
import std.format;
import std.file;
import std.datetime;

import serverino;
import page;
import plugin;


mixin ServerinoMain;

debug
    enum int CACHE_MAXAGE = 1;
else
    enum int CACHE_MAXAGE = 3600*24;

// one main entry point
void hello(const Request req, Output output)
{
    initialization();
    const(char)[] url = req.path();

    writefln("GET %s", url);

    const(char)[][] urlParts = split(url, "/");

    if (urlParts.length < 2)
    {
        showError404(output);
    }

    // drop first work (usually "" since URLs begin with /)
    urlParts = urlParts[1..$];

    if (url == "/")
    {
        showHome(output);
    }
    else switch(urlParts[0]) 
    {
    case "made-with-dplug":
        showMadeWith(output);
        break;

    case "public":
        {   
            if (urlParts.length < 2)
            {
                showError404(output);
                break;
            }
            const(char)[] rest = join(urlParts[0..$], "/");
            output.setExpires(CACHE_MAXAGE);
            output.serveFile(rest.idup);
            break;
        }


    default:
        showError404(output);
    }
}

void showError404(ref Output output)
{
    output.status = 404;
    output ~= "Page not found";
}

enum
{
    PAGE_FEATURES,
    PAGE_MADEWITH
}

void showHome(ref Output output)
{
    Page page;
    makeSitepageEnter(page, PAGE_FEATURES);
    page.insertMarkdown("markdown/content.md");
    makeSitepageExit(page);

    output.setExpires(CACHE_MAXAGE);
    string cacheHTMLPath = "index.html";
    output.serveFileAndCache(cacheHTMLPath, to!string(page));
}

void showMadeWith(ref Output output)
{
    Page page;
    makeSitepageEnter(page, PAGE_MADEWITH);

    page.div(`class="grid is-col-min-15"`);
    
    foreach(plugin; g_plugins)
    with(page)
    {
        div(`class="cell"`);
        div(`class="card"`);
            div(`class="card-image"`);

                a(plugin.link, `class="link"`);
                    begin("figure", `class="image"`);
                        img(plugin.screenshot, "Screenshot");
                    end;
                end;
            end;

            div(`class="card-content"`);
                div(`class="media"`);
                    p(`class="title is-4"`);
                        write(plugin.name);
                    end;
                    p(`class="subtitle is-6 pl-4"`);
                        write("by " ~ plugin.vendor);
                    end;
                end;

                div(`class="content"`);
                    write(plugin.description);
                end;

                a(plugin.link, `class="link"`);
                    spanText("Download");
                end;
            end;
        end("div");
        end;
    }
    page.end;

    makeSitepageExit(page);
    output.setExpires(CACHE_MAXAGE);
    string cacheHTMLPath = "made-with-dplug.html";
    output.serveFileAndCache(cacheHTMLPath, to!string(page));
}

void makeSitepageEnter(ref Page page, int selectedPage)
{
    page.htmlHeader("dplug.org", "The Dplug Audio Plug-in Framework.");
    page.begin("body");
    makeSiteNavbar(page, selectedPage);
}

void makeSiteNavbar(ref Page page, int selectedPage)
{
    with(page)
    {
        begin("nav", `class="navbar" role="navigation" aria-label="main navigation"`);
            div(`class="navbar-brand"`);
                a("/", `class="navbar-item"`);
                    img("/public/dplug-logo.png", "Dplug Logo", `class="dplug-logo"`);
                end;

                /*        <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="navbarBasicExample">
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                </a> --> */
            end("div");

            div(`id="navbarBasicExample" class="navbar-menu"`);
                div(`class="navbar-start"`);

                    a("/", format(`class="navbar-item %s"`, selectedPage == PAGE_FEATURES ? " is-selected":""));
                        icon("lni-home-2");
                        spanText("FEATURES");
                    end;
           
                    a("/made-with-dplug", format(`class="navbar-item %s"`, selectedPage == PAGE_MADEWITH ? " is-selected":""));
                        icon("lni-heart");
                        spanText("MADE WITH DPLUG");
                    end;

                    a("/tutorials", `class="navbar-item button"`);
                        icon("lni-book-open");
                        spanText("TUTORIALS");
                    end;
                end("div");

                div(`class="navbar-end"`);
                    div(`class="navbar-item"`);
                        div(`class="buttons"`);
                            a("https://github.com/AuburnSounds/Dplug", `class="button is-light"`);
                                icon("lni-github");
                                spanText("OPEN SOURCE");
                            end;

                            a("https://discord.gg/7PdUvUbyJs", `class="button is-primary"`);
                                icon("lni-discord");
                                spanText("DISCORD");
                            end;
                        end;
                    end;
                end;
            end;
        end("nav");
    }
}

void makeSitepageExit(ref Page page)
{
    page.end("body");
    page.write("</html>");
}

void setExpires(ref Output output, int whenFromNowSeconds)
{
    output.addHeader("Cache-Control", format("public, max-age=%d", whenFromNowSeconds));
    output.addHeader("Expires", "Tue, 31 Dec 2030 14:00:00 GMT");
}

// with serverino, can't return a large request without a file...
void serveFileAndCache(ref Output output, const(char)[] cachePath, const(void)[] data)
{
    // I don't think this is needed to cache since
    // the CDN is used for that.
    string filePath = ("cache/" ~ cachePath).idup;
    std.file.write(filePath, data);
    output.serveFile(filePath);
}

@onServerInit ServerinoConfig setup()
{
    ServerinoConfig sc = ServerinoConfig.create(); // Config with default params
    sc.addListener("127.0.0.1", 8089);
    sc.setWorkers(4);
    sc.setMaxRequestSize(100_000_000); // 100 MB
    sc.setMaxRequestTime(60.seconds);
    return sc;
}


__gshared bool g_Init = false;

__gshared Plugin[] g_plugins;

shared static this()
{
    initialization();
}

void initialization()
{
    if (g_Init)
        return;

    g_Init = true;

    g_plugins = parsePlugins();
    writeln("Found %s example plugins", g_plugins.length);

    // note that each httpd worker will do this, since being several processes.
    // If there is website initialization (things to read) do it here
}

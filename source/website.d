import std;
import commonmarkd;
import serverino;
import page;

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

    //output ~= req.dump(); 

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



void showMarkdownPage(ref Output output, string mdfilePath)
{
    Page page;
    makeSitepageEnter(page);

    page.s ~= `<div class="container">`;
    page.s ~= `<div class="markdown-page">`;
    const(char)[] markdown = cast(char[]) std.file.read(mdfilePath);

    MarkdownFlag flags = MarkdownFlag.dialectGitHub;
    page.s ~= convertMarkdownToHTML(markdown,flags);
    page.s ~= `</div>`;
    page.s ~= `</div>`;

    makeSitepageExit(page);

    // Will not need to do that for one day

    output.setExpires(CACHE_MAXAGE);
    string cacheHTMLPath = baseName(mdfilePath) ~ ".html";
    output.serveFileAndCache(cacheHTMLPath, to!string(page));
}

void showHome(ref Output output)
{
    showMarkdownPage(output, "markdown/content.md");
}


void makeSitepageEnter(ref Page page)
{
    with (page)
    {
        htmlHeader("dplug.org", "The Dplug Audio Plug-in Framework.");
        begin("body");
    }


    makeSiteNavbar(page);
}

void makeSiteNavbar(ref Page page)
{
    with(page)
    {
        begin("nav", `class="navbar" role="navigation" aria-label="main navigation"`);
            div(`class="navbar-brand"`);
                a(`class="navbar-item" href="/"`);
                    img("/public/dplug-logo.png", "Dplug Logo", `class="dplug-logo"`);
                end;

                     /*  <!--         <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="navbarBasicExample">
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                </a> --> */
            end("div");

            div(`id="navbarBasicExample" class="navbar-menu"`);
                div(`class="navbar-start"`);

                    div(`class="navbar-item"`);
                        a("/", `class="navbar-link"`);
                            icon("lni-home-2");
                            spanText("WHAT'S THIS?");
                        end;
                    end;

                    div(`class="navbar-item"`);
                        a("/", `class="navbar-link"`);
                            icon("lni-stars");
                            spanText("MADE WITH DPLUG");
                        end;
                    end;

                     div(`class="navbar-item"`);
                        a("/", `class="navbar-link"`);
                            icon("lni-book-open");
                            spanText("TUTORIALS");
                        end;
                    end;
                end("div");

                div(`class="navbar-end"`);
                    div(`class="navbar-item"`);
                        div(`class="buttons"`);
                            a("https://github.com/AuburnSounds/Dplug", `class="button is-light"`);
                                icon("lni-github");
                                spanText("ASK QUESTION");
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

shared static this()
{
    initialization();
}

void initialization()
{
    if (g_Init)
        return;
    g_Init = true;

    // note that each httpd worker will do this, since being several processes.

    // If there is website initialization (things to read) do it here
}

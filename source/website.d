import std.stdio;
import std.array;
import std.conv;
import std.format;
import std.file;
import std.datetime;

import serverino;
import page;
import plugin;
import article;
import websitecore;

mixin ServerinoMain;


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
    case "tutorials":
        string seltag = null;
        if (urlParts.length >= 2 && urlParts[1] == "tag")
            seltag = urlParts[2].idup;
        showTutorials(output, seltag);
        break;

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
            rest = rest.replace("%20", " ");
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

enum
{
    THEME_LIGHT = false,
    THEME_DARK = true
}

void showHome(ref Output output)
{
    Page page;
    makeSitepageEnter(page, PAGE_FEATURES, THEME_DARK);
 //   page.insertMarkdown("markdown/content.md");
    with(page)
    {
        div(`class="container my-6"`);
            div(`class="columns is-family-monospace"`);
                div(`class="column m-4"`);
                    div(`class="title is-1"`);
                        write(`<span class="main-title">DPLUG<br></span>`);
                        write("Opensource lightweight audio framework");   

                        div(`class="box mt-6"`);
                            begin("figure", `class="image"`);
                                img("/public/examples.webp", "Dplug examples");
                            end;
                            a("/made-with-dplug");
                                write(`<button class="button is-danger is-large alt-button">See plug-ins made with Dplug…</button>`);
                            end;
                        end;
                    end;

                end;

                div(`class="column m-4"`);
                    p(`class="title is-2"`);
                        begin("figure", `class="image mt-6"`);
                            img("/public/dplug-logo.png", "Dplug logo", `class="main-logo"`);
                        end;
                    end;
                end;
            end;

            div(`class="columns is-family-monospace"`);
                div(`class="column m-4"`);
                    p(`class="title is-2"`);
                        write(`<span class="main-title">KEY BENEFITS<br></span>`);
                        write(`<span style="font-size: 0.7em">`);
                        write("♦ FAST TO USE<br>");
                        write("♦ OPEN SOURCE<br>");
                        write("♦ FREE OF CHARGE NO CAP<br>");
                        write(`♦ EASY TO SETUP<br>`);                        
                        write("♦ EXAMPLES TO START WITH<br>");
                        write("♦ LOW MAINTENANCE<br>");
                        write("♦ SUPPORTIVE COMMUNITY!<br><br>");
                        write("MAKE FLOSS OR PAID PLUG-IN:<br>");
                        write("♦ VST3 / VST2 / AU / AAX / CLAP / FLP / LV2<br>");
                        write("♦ WINDOWS / MACOS / LINUX");
                        write(`</span>`);
                    end;
                end;

                div(`class="column m-4"`);
                    p(`class="container my-4 theme-light"`);
                        a("https://github.com/AuburnSounds/Dplug/wiki/Getting-Started");
                            begin("button", `class="button is-large is-fullwidth p-5 title is-family-monospace main-button"`);
                                write("HOW TO INSTALL AND START");
                                write(`<span class="hide">&lt;</span>`);
                            end;
                        end;

                        a(DISCORD_LINK);
                            begin("button", `class="button is-large is-fullwidth p-5 title is-family-monospace main-button"`);
                                write("COMMUNITY FORUM"); 
                                write(`<span class="hide">&lt;</span>`);
                            end;
                        end;

                        a("/tutorials");
                            begin("button", `class="button is-large is-fullwidth p-5 title is-family-monospace main-button"`);
                                write("DOCUMENTATION & SUPPORT");                    
                            end;
                        end;

                        a(GITHUB_LINK);
                            begin("button", `class="button is-large is-fullwidth p-5 title is-family-monospace main-button"`);
                                write("SOURCE CODE & DETAILS");                    
                            end;
                        end;
                    end;
                end;
            end;
        end;
    }
    makeSitepageExit(page);

    output.setExpires(CACHE_MAXAGE);
    string cacheHTMLPath = "index.html";
    output.serveFileAndCache(cacheHTMLPath, to!string(page));
}

void showMadeWith(ref Output output)
{
    Page page;
    makeSitepageEnter(page, PAGE_MADEWITH, THEME_DARK);

    page.div(`class="container"`);
        page.div(`class="content"`);
            page.insertMarkdown("markdown/made-with-dplug.md");
        page.end;

        
    page.end;

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

void showTag(ref Page page, string tag)
{
    page.a("/tutorials/tag/" ~ tag);
    string cat = convertTagToCategory(tag);
    page.write(format(`<span class="tag %s mx-1">%s</span>`, cat, "#" ~ tag));
    page.end;
}

void showTutorials(ref Output output, string seltag)
{
    Page page;
    makeSitepageEnter(page, PAGE_TUTORIALS, THEME_LIGHT);

    page.div(`class="container p-4"`);
        page.div(`class="content"`);
            page.insertMarkdown("markdown/tutorials.md");
        page.end;
    page.end;


    page.div(`class="container p-4 content "`);
    page.spanText("Tags: ");
    with(page)
        foreach(tag; KNOWN_TAGS)
        {
            page.showTag(tag);           
        }
    page.end;

    if (seltag)
    {
        page.div(`class="container p-4 content"`);
        page.spanText("Filter: ");
           page.showTag(seltag);

           page.a("/tutorials");
               page.write(`<span class="tag is-hoverable is-light mx-1">✖&nbsp;clear</span>`);
           page.end;
        page.end;
    }

    page.div(`class="grid is-col-min-18"`);

    int qcount = 0;
    foreach(article; g_articles)
    if (seltag is null || article.hasTag(seltag))
    with(page)
    {
        qcount++;
        div(`class="cell"`);
            div(`class="card p-1"`);
                div(`class="card-image"`);

                    a(article.link, `class="link"`);
                        begin("figure", `class="image is-128x128 mx-auto mt-5"`);
                            img(article.thumbnail, "Thumbnail"); // retina, since 256x256
                        end;
                    end;
                end;
       
                div(`class="card-content is-size-5"`);
                    
                    p(`class="content my-4"`);
                        begin("blockquote");
                            write(article.description);
                        end;
                    end;

                    div(`class="content is-size-7 is-italic mx-4 my-2"`);
                        write(article.elevatorPitch);
                    end;
 
                    div(`class="button link"`);
                        write("See:&nbsp;");
                        a(article.link);
                            string title = article.title;
                            if (article.isPDF) title ~= "&nbsp;(PDF)";
                            write(title);
                        end;
                    end;
                                       
                    div(`class="is-size-6 my-2"`);
                        foreach(tag; article.tags)
                        {
                            showTag(page, tag);
                        }
                    end;
                end;
            end("div");
        end;
    }
    page.end;

    page.div(`class="container p-4 is-pulled-right content "`);
        page.spanText(format("Found %s questions.", qcount));
    page.end;

    makeSitepageExit(page);
    output.setExpires(CACHE_MAXAGE);
    string cacheHTMLPath = "made-with-dplug.html";
    output.serveFileAndCache(cacheHTMLPath, to!string(page));
}



@onServerInit ServerinoConfig setup()
{
    ServerinoConfig sc = ServerinoConfig.create(); // Config with default params
    sc.addListener("127.0.0.1", 8089);
    sc.setWorkers(2);
    sc.setMaxRequestSize(100_000_000); // 100 MB
    sc.setMaxRequestTime(60.seconds);
    return sc;
}


__gshared bool g_Init = false;

__gshared Plugin[] g_plugins;
__gshared Article[] g_articles;

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
    writefln("Found %s example plugins", g_plugins.length);

    g_articles = parseArticles();
    writefln("Found %s articles/questions", g_articles.length);

    // note that each httpd worker will do this, since being several processes.
    // If there is website initialization (things to read) do it here
}

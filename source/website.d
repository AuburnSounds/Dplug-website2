import std;
import commonmarkd;
import serverino;

mixin ServerinoMain;

debug
    enum int CACHE_MAXAGE = 1;
else
    enum int CACHE_MAXAGE = 3600*24;

// one main entry point
void hello(const Request req, Output output)
{
    initialization();
    const(char)[] url = req.uri();

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
    page.htmlHeader("dplug.org", "The Dplug Audio Plug-in Framework.");

    page.s ~= `

        <body>

    `;


    //  main Navbar
    page.s ~= `
        <nav class="navbar" role="navigation" aria-label="main navigation">
            <div class="navbar-brand">
                <a class="navbar-item" href="/">
                    <img class="dplug-logo" src="/public/dplug-logo.png">
                </a>

       <!--         <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="navbarBasicExample">
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                    <span aria-hidden="true"></span>
                </a> -->
            </div>

            <div id="navbarBasicExample" class="navbar-menu">
                <div class="navbar-start">

                    <div class="navbar-item">
                        <a lass="navbar-link" href="/">
                        <span class="icon"><i class="lni lni-home-2"></i></span>
                        <span>WHAT'S THIS?</span>
                        </a>
                    </div>

                    <div class="navbar-item">
                        <a class="navbar-link" href="/projects">
                            <span class="icon"><i class="lni lni-stars"></i></i></span>
                            <span>MADE WITH DPLUG</span>
                        </a>
                    </div>

                    <div class="navbar-item">
                        <a class="navbar-link">
                            <span class="icon"><i class="lni lni-book-open"></i></span>
                            <span>TUTORIALS</span>
                        </a>
                    </div>
                </div>
            </div>

            <div class="navbar-end">
                <div class="navbar-item">
                    <div class="buttons">

                        <a class="button is-light" href="https://github.com/AuburnSounds/Dplug">
                            <span class="icon"><i class="lni lni-github"></i></span>
                            <span class="is-hidden-mobile">REPORT ISSUE</span>
                        </a>

                        <a class="button is-primary" href="https://discord.gg/7PdUvUbyJs">
                            <span class="icon"><i class="lni lni-discord"></i></span>
                            <span class="is-hidden-mobile">COMMUNITY</span>
                        </a>
                    </div>
                </div>
            </div>
        </nav>`;
}

void makeSitepageExit(ref Page page)
{
    page.s ~= q"[



        </body>
        </html>
        ]";
}

struct Page
{
    string s;

    void htmlHeader(string title, string description)
    {
        s ~= `<!doctype html>`;
        s ~= `<html lang="en" data-theme="dark">`;
        s ~= `<head>`;
        s ~= `<meta charset="utf-8">`;
        s ~= `<meta name="viewport" content="width=device-width, initial-scale=1.0">`;
        s ~= format(`<meta name="description" content="%s">`, description);
        s ~= format(`<title>%s</title>`, title);
        s ~= `<link rel="stylesheet" href="/public/bulma.min.css">`;
        s ~= `<link rel="stylesheet" href="https://cdn.lineicons.com/5.0/lineicons.css">`;
        s ~= `<link rel="stylesheet" href="/public/website.css">`;
        s ~= `</head>`;
    }

    string toString()
    {
        return s;
    }

    void append(const(char)[] content)
    {
        s ~= content;
    }

}

void setExpires(ref Output output, int whenFromNowSeconds)
{
    output.addHeader("Cache-Control", format("public, max-age=%d", whenFromNowSeconds));
    output.addHeader("Expires", "Tue, 31 Dec 2030 14:00:00 GMT");
}

// with serverino, can't return a large request without a file...
void serveFileAndCache(ref Output output, const(char)[] cachePath, const(void)[] data)
{
    string filePath = ("cache/" ~ cachePath).idup;
    std.file.write(filePath, data);
    output.serveFile(filePath);
}

@onServerInit ServerinoConfig setup()
{
    ServerinoConfig sc = ServerinoConfig.create(); // Config with default params
    sc.addListener("127.0.0.1", 8089);
    return sc;
}

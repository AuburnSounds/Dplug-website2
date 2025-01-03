module websitecore;

import std.format;
import std.file;

import serverino;
import page;

enum
{
    PAGE_FEATURES,
    PAGE_MADEWITH,
    PAGE_TUTORIALS
}

enum DISCORD_LINK = "https://discord.gg/7PdUvUbyJs";
enum GITHUB_LINK = "https://github.com/AuburnSounds/Dplug";

debug
    enum int CACHE_MAXAGE = 1;
else
    enum int CACHE_MAXAGE = 3600*24;

void makeSitepageEnter(ref Page page, int selectedPage, bool darkTheme)
{
    page.htmlHeader("dplug.org", "The Dplug Audio Plug-in Framework.", darkTheme);

    if (darkTheme)
    {
        page.begin("body", `style="background-color: rgb(28,28,41)"`);
    }
    else
    {
        page.begin("body");
    }
    makeSiteNavbar(page, selectedPage);
}

void makeSiteNavbar(ref Page page, int selectedPage)
{
    with(page)
    {
        begin("nav", `class="navbar theme-light" role="navigation" aria-label="main navigation"`);
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

        a("/", format(`class="navbar-item is-light%s"`, selectedPage == PAGE_FEATURES ? " is-selected nav-selected":""));
        //icon("lni-home-2");
        spanText("FEATURES");
        end;

        a("/made-with-dplug", format(`class="navbar-item is-light%s"`, selectedPage == PAGE_MADEWITH ? " is-selected nav-selected":""));
        //icon("lni-heart");
        spanText("MADE WITH DPLUG");
        end;

        a("/tutorials", format(`class="navbar-item button is-light%s"`, selectedPage == PAGE_TUTORIALS ? " is-selected nav-selected":""));
        //icon("lni-book-open");
        spanText("TUTORIALS");
        end;
        end("div");

        div(`class="navbar-end"`);
        div(`class="navbar-item"`);
        div(`class="buttons"`);
        a(GITHUB_LINK, `class="button is-light"`);
        icon("lni-github");
        spanText("OPEN SOURCE");
        end;

        a(DISCORD_LINK, `class="button is-primary"`);
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
    page.begin("footer", `class="footer mt-6"`);
    
    page.write(`
        <div class="content has-text-centered">
            <p>
            Dplug framework by the Dplug contributors. Website content is licensed
                    <a href="https://creativecommons.org/licenses/by-nc-sa/4.0//"
                    >CC BY NC SA 4.0</a
                    >.
            </p>
        </div>`);
    page.end("footer");
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
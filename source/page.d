module page;

import std.format;
import std.file;
import commonmarkd;

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

    string[] tagStack;

    void begin(string tag, string stuff = null)
    {
        tagStack ~= tag;
        if (stuff !is null)
            s ~= `<` ~ tag ~ ` ` ~ stuff ~ `>`;
        else
            s ~= `<` ~ tag ~ `>`;
    }

    void end(string tag = null) // optionally: verify tag
    {
        if (tag !is null)
        {
            if (tagStack[$-1] != tag)
                throw new Exception("exit tag mismatch");
        }
        s ~= `</` ~ tagStack[$-1] ~ `>`;
        tagStack = tagStack[0..$-1];
    }

    void div(string stuff = null)
    {
        begin("div", stuff);
    }
    void span(string stuff = null)
    {
        begin("span", stuff);
    }
    void p(string stuff = null)
    {
        begin("p", stuff);
    }
    void a(string href, string stuff = null)
    {
        stuff = format(`href="%s"%s`, href, stuff?stuff:"");
        begin("a", stuff);
    }
    void img(string src, string desc, string stuff = null)
    {
        string tag = format(`<img src="%s" alt="%s"%s>`, src, desc, stuff ? (" "~stuff):"");
        s ~= tag;
    }

    void spanText(string text)
    {
        begin("span");
        s ~= text;
        end;
    }
    void icon(string iconname)
    {
        s ~= format(`<span class="icon"><i class="lni %s"></i></span>`, iconname);
    }

    void insertMarkdown(string mdfilePath)
    {
        div(`class="container"`);            
            const(char)[] markdown = cast(char[]) std.file.read(mdfilePath);
            MarkdownFlag flags = MarkdownFlag.dialectGitHub;
            s ~= convertMarkdownToHTML(markdown,flags);
        end;
    }

    void write(string t)
    {
        s ~= t;
    }
}

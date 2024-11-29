module article;

import std;
import yxml;

class Article
{
   string title;
   string link;
   string description;
   string thumbnail;
   string elevatorPitch;
   string[] tags;

   bool hasTag(const(char)[] t)
   {
       foreach(tag; tags)
           if (t == tag)
               return true;
       return false;
   }
}

string[] KNOWN_TAGS =
[
    "cpu", "d", "dplug", "dsp", "music", "other", "ui"
];


string convertTagToCategory(string tag)
{
    switch(tag)
    {
        case "dplug": return "is-hoverable is-success is-light";
        case "ui":    return "is-hoverable is-warning is-light";
        case "dsp":   return "is-hoverable is-link is-light";
        case "music": return "is-hoverable is-primary is-light";
        case "d":     return "is-hoverable is-danger is-light";
        case "cpu":   return "is-hoverable is-info is-light";
        case "other": return "is-hoverable is-light";
        default: 
            writefln("Unknonw tag %s", tag);
            assert(false);
    }
}

Article[] parseArticles()
{
	Article[] res;
    string content = cast(string)(std.file.read("articles.xml"));
    XmlDocument doc;
    doc.parse(content);
    if (doc.isError)
        throw new Exception(doc.errorMessage.idup);

    int xmlItemIndex = 0;

    XmlElement nodePlugins = doc.root;
    {
        foreach(nodePlugin; nodePlugins.getChildrenByTagName("article"))
        {
            Article a = new Article;
            a.title = nodePlugin.getUniqueTagString("title");
            a.link = nodePlugin.getUniqueTagString("link");
            a.description = nodePlugin.getUniqueTagString("description");
            a.thumbnail = nodePlugin.getUniqueTagString("thumbnail");
            a.elevatorPitch = nodePlugin.getUniqueTagString("elevator-pitch");

            foreach(nodeTag; nodePlugin.getChildrenByTagName("tag"))
            {
                a.tags ~= nodeTag.innerHTML.idup;
            }
            sort(a.tags);
            res ~= a;
        }
    }
    
    return res;
}

bool hasTag(XmlElement elem, string tagName)
{
    XmlElement result = null;
    foreach(e; elem.getChildrenByTagName(tagName))
    {
        result = e;
    }
    return result !is null;
}

XmlElement getUniqueTag(XmlElement elem, string tagName)
{
    XmlElement result = null;
    foreach(e; elem.getChildrenByTagName(tagName))
    {
        if (result !is null)
            throw new Exception(format("Too many \"%s\" tags", tagName));
        result = e;
    }
    if (result is null)
        throw new Exception(format("Missing tag \"%s\"", tagName));
    return result;
}

string getUniqueTagString(XmlElement elem, string tagName)
{
    return getUniqueTag(elem, tagName).getStrippedInnerHTML();
}

string getStrippedInnerHTML(XmlElement elem)
{
    return strip(elem.innerHTML).idup;
}


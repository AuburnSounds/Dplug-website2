module article;

import std;
import yxml;

class Article
{
   string title;
   string link;
   string description;
   string thumbnail;
   string[] tags;
}


string convertTagToCategory(string tag)
{
    switch(tag)
    {
        case "Dplug": return "is-hoverable is-success is-light";
        case "UI":    return "is-hoverable is-Warning is-light";
        case "Wren":  return "is-hoverable is-warning is-light";
        case "DSP":   return "is-hoverable is-light";
        case "Music": return "is-hoverable is-primary is-light";
        case "D":     return "is-hoverable is-danger is-light";
        case "Faust": return "is-hoverable is-black is-light";
        case "CPU":   return "is-hoverable is-info is-light";
        case "DAW":   return "is-hoverable is-dark is-light";
        case "OSS":   return "is-hoverable is-white is-light";
    default: 
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


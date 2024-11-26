module plugin;

import std;
import yxml;

class Plugin
{
   string name;
   string vendor;
   string link;
   string screenshot;
   string description;
}

Plugin[] parsePlugins()
{
	Plugin[] res;
    string content = cast(string)(std.file.read("showcase.xml"));
    XmlDocument doc;
    doc.parse(content);
    if (doc.isError)
        throw new Exception(doc.errorMessage.idup);

    int xmlItemIndex = 0;

    XmlElement nodePlugins = doc.root;
    {
        foreach(nodePlugin; nodePlugins.getChildrenByTagName("plugin"))
        {
            Plugin plugin = new Plugin;
            plugin.name = nodePlugin.getUniqueTagString("name");
            plugin.vendor = nodePlugin.getUniqueTagString("vendor");
            plugin.link = nodePlugin.getUniqueTagString("link");
            plugin.screenshot = nodePlugin.getUniqueTagString("screenshot");
            plugin.description = nodePlugin.getUniqueTagString("description");
            res ~= plugin;
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


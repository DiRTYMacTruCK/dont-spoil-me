using System;
using System.Collections.Generic;
using Jellyfin.Plugin.DontSpoilMe.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Model.Plugins;
using MediaBrowser.Model.Serialization;

[assembly: System.Reflection.AssemblyCompanyAttribute("DiRTYMacTruCK")]
[assembly: System.Reflection.AssemblyProductAttribute("dont-spoil-me")]

namespace Jellyfin.Plugin.DontSpoilMe;

public class Plugin : BasePlugin<PluginConfiguration>, IHasWebPages
{
    public Plugin(IApplicationPaths applicationPaths, IXmlSerializer xmlSerializer)
        : base(applicationPaths, xmlSerializer)
    {
        Instance = this;
    }

    public override string Name => "dont-spoil-me";
    public override Guid Id => Guid.Parse("b2c3d4e5-f6a7-8901-bcde-f12345678901");
    public override string Description => "Replaces episode thumbnail images with the series poster to prevent spoilers.";
    public static Plugin? Instance { get; private set; }

    public IEnumerable<PluginPageInfo> GetPages()
    {
        yield return new PluginPageInfo
        {
            Name = "dont-spoil-me",
            EmbeddedResourcePath = $"{GetType().Namespace}.Configuration.configPage.html",
            EnableInMainMenu = false
        };
    }
}

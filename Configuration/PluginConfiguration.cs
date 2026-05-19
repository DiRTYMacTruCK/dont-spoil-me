using MediaBrowser.Model.Plugins;

namespace Jellyfin.Plugin.DontSpoilMe.Configuration;

public class PluginConfiguration : BasePluginConfiguration
{
    public bool IsEnabled { get; set; } = true;
    public bool OnlyUnwatched { get; set; } = true;
}

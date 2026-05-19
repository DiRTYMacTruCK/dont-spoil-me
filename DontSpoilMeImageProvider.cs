using System.Collections.Generic;
using System.Linq;
using MediaBrowser.Controller.Entities;
using MediaBrowser.Controller.Entities.TV;
using MediaBrowser.Controller.Providers;
using MediaBrowser.Model.Entities;
using MediaBrowser.Model.IO;
using Microsoft.Extensions.Logging;

namespace Jellyfin.Plugin.DontSpoilMe;

public class DontSpoilMeImageProvider : ILocalImageProvider, IHasOrder
{
    private readonly ILogger<DontSpoilMeImageProvider> _logger;

    public DontSpoilMeImageProvider(ILogger<DontSpoilMeImageProvider> logger)
    {
        _logger = logger;
    }

    public int Order => 0;
    public string Name => "dont-spoil-me";
    public bool Supports(BaseItem item) => item is Episode;

    public IEnumerable<LocalImageInfo> GetImages(BaseItem item, IDirectoryService directoryService)
    {
        var config = Plugin.Instance?.Configuration;
        if (config is null || !config.IsEnabled)
            yield break;

        if (item is not Episode episode)
            yield break;

        if (config.OnlyUnwatched && episode.UserData != null && episode.UserData.Any(u => u.Played))
            yield break;

        var series = episode.Series;
        if (series is null)
        {
            _logger.LogDebug("dont-spoil-me: no series found for episode {Id}", episode.Id);
            yield break;
        }

        var seriesImageInfo = series.GetImageInfo(ImageType.Primary, 0);
        if (seriesImageInfo is null || string.IsNullOrEmpty(seriesImageInfo.Path))
        {
            _logger.LogDebug("dont-spoil-me: series {SeriesId} has no Primary image", series.Id);
            yield break;
        }

        _logger.LogDebug("dont-spoil-me: swapping episode {EpisodeId} thumb with series poster", episode.Id);

        yield return new LocalImageInfo
        {
            FileInfo = new FileSystemMetadata { FullName = seriesImageInfo.Path, IsDirectory = false },
            Type = ImageType.Primary
        };
    }
}

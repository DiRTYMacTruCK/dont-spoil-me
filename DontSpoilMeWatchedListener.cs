using System;
using System.Threading;
using System.Threading.Tasks;
using MediaBrowser.Controller.Entities.TV;
using MediaBrowser.Controller.Library;
using MediaBrowser.Model.Entities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Jellyfin.Plugin.DontSpoilMe;

public class DontSpoilMeWatchedListener : IHostedService
{
    private readonly IUserDataManager _userDataManager;
    private readonly ILogger<DontSpoilMeWatchedListener> _logger;

    public DontSpoilMeWatchedListener(
        IUserDataManager userDataManager,
        ILogger<DontSpoilMeWatchedListener> logger)
    {
        _userDataManager = userDataManager;
        _logger = logger;
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _userDataManager.UserDataSaved += OnUserDataSaved;
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _userDataManager.UserDataSaved -= OnUserDataSaved;
        return Task.CompletedTask;
    }

    private void OnUserDataSaved(object? sender, UserDataSaveEventArgs e)
    {
        var config = Plugin.Instance?.Configuration;
        if (config is null || !config.IsEnabled || !config.OnlyUnwatched)
            return;

        if (e.Item is not Episode episode)
            return;

        if (!e.UserData.Played)
            return;

        _logger.LogInformation("dont-spoil-me: episode {Id} marked watched, removing image override", episode.Id);

        try
        {
            episode.DeleteImageAsync(ImageType.Primary, 0).GetAwaiter().GetResult();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "dont-spoil-me: failed to delete image for episode {Id}", episode.Id);
        }
    }
}

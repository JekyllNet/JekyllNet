using JekyllNet.Cli;

namespace JekyllNet.Tests;

public sealed class CliRuntimeTests
{
    [Fact]
    public async Task BuildOnce_WritesDestinationToGitHubOutput_WhenEnabled()
    {
        var sourceDirectory = TestInfrastructure.GetRepoPath("sample-site");
        var destinationDirectory = Path.Combine(Path.GetTempPath(), "JekyllNet.Tests", Guid.NewGuid().ToString("N"));
        var githubOutputPath = Path.Combine(Path.GetTempPath(), "JekyllNet.Tests", Guid.NewGuid().ToString("N"), "github-output.txt");
        Directory.CreateDirectory(Path.GetDirectoryName(githubOutputPath)!);

        var previousGithubOutput = Environment.GetEnvironmentVariable("GITHUB_OUTPUT");
        Environment.SetEnvironmentVariable("GITHUB_OUTPUT", githubOutputPath);

        try
        {
            var settings = new BuildCommandSettings(
                sourceDirectory,
                destinationDirectory,
                IncludeDrafts: false,
                IncludeFuture: false,
                IncludeUnpublished: false,
                PostsPerPage: null,
                WriteGitHubOutputDestination: true);

            using var output = new StringWriter();
            await CliRuntime.BuildOnceAsync(settings, output, CancellationToken.None);

            Assert.True(File.Exists(Path.Combine(destinationDirectory, "index.html")));
            Assert.Contains($"Build complete: {destinationDirectory}", output.ToString(), StringComparison.Ordinal);

            var githubOutput = await File.ReadAllTextAsync(githubOutputPath);
            Assert.Contains($"destination={destinationDirectory}", githubOutput, StringComparison.Ordinal);
        }
        finally
        {
            Environment.SetEnvironmentVariable("GITHUB_OUTPUT", previousGithubOutput);

            if (Directory.Exists(destinationDirectory))
            {
                Directory.Delete(destinationDirectory, recursive: true);
            }

            var githubOutputDirectory = Path.GetDirectoryName(githubOutputPath);
            if (!string.IsNullOrWhiteSpace(githubOutputDirectory) && Directory.Exists(githubOutputDirectory))
            {
                Directory.Delete(githubOutputDirectory, recursive: true);
            }
        }
    }
}

using OpenFeature;
using OpenFeature.Providers.Memory;

namespace Example.Tests;

/// <summary>
/// Tests for the <see cref="ExampleClass"/> class.
/// </summary>
public class ExampleClassTests
{
  /// <summary>
  /// Verifies that <see cref="ExampleClass.Add(int, int)"/> returns the sum of its two operands.
  /// </summary>
  [Fact]
  public void Add_TwoOperands_ReturnsTheirSum()
  {
    // Arrange
    int augend = 2;
    int addend = 3;

    // Act
    int sum = ExampleClass.Add(augend, addend);

    // Assert
    Assert.Equal(5, sum);
  }

  /// <summary>
  /// Verifies that <see cref="ExampleClass.Add(int, int)"/> returns the correct sum when one operand is negative.
  /// </summary>
  [Fact]
  public void Add_NegativeOperand_ReturnsTheirSum()
  {
    // Arrange
    int augend = 10;
    int addend = -4;

    // Act
    int sum = ExampleClass.Add(augend, addend);

    // Assert
    Assert.Equal(6, sum);
  }

  /// <summary>
  /// Verifies <see cref="FeatureFlags.DescribeAsync(IFeatureClient)"/> takes the OFF
  /// branch when the example flag is registered default-off (the scaffold default).
  /// </summary>
  [Fact]
  public async Task DescribeAsync_FlagDefaultOff_ReturnsOffMessage()
  {
    // Arrange
    var client = await FeatureFlags.CreateClientAsync(FeatureFlags.CreateInMemoryProvider());

    // Act
    string result = await FeatureFlags.DescribeAsync(client);

    // Assert
    Assert.Contains("is off", result, StringComparison.Ordinal);
  }

  /// <summary>
  /// Verifies <see cref="FeatureFlags.DescribeAsync(IFeatureClient)"/> takes the ON
  /// branch when the example flag resolves on.
  /// </summary>
  [Fact]
  public async Task DescribeAsync_FlagOn_ReturnsOnMessage()
  {
    // Arrange
    var client = await FeatureFlags.CreateClientAsync(BuildExampleProvider(enabled: true));

    // Act
    string result = await FeatureFlags.DescribeAsync(client);

    // Assert
    Assert.Contains("is on", result, StringComparison.Ordinal);
  }

  /// <summary>
  /// Verifies an unset flag falls back to the OFF default, so a missing flag definition
  /// never silently turns a feature on.
  /// </summary>
  [Fact]
  public async Task DescribeAsync_FlagUnset_DefaultsToOff()
  {
    // Arrange
    var provider = new InMemoryProvider(new Dictionary<string, Flag>(StringComparer.Ordinal));
    var client = await FeatureFlags.CreateClientAsync(provider);

    // Act
    string result = await FeatureFlags.DescribeAsync(client);

    // Assert
    Assert.Contains("is off", result, StringComparison.Ordinal);
  }

  /// <summary>
  /// Builds an in-memory provider that resolves <see cref="FeatureFlags.ExampleFeature"/>
  /// to <paramref name="enabled"/>, so both flag states can be exercised.
  /// </summary>
  /// <param name="enabled">Whether the example flag should resolve on.</param>
  /// <returns>An in-memory provider resolving the example flag to <paramref name="enabled"/>.</returns>
  static InMemoryProvider BuildExampleProvider(bool enabled)
  {
    string variant = enabled ? "on" : "off";
    return new InMemoryProvider(new Dictionary<string, Flag>(StringComparer.Ordinal)
    {
      [FeatureFlags.ExampleFeature] = new Flag<bool>(
        new Dictionary<string, bool>(StringComparer.Ordinal) { ["on"] = true, ["off"] = false },
        variant),
    });
  }
}

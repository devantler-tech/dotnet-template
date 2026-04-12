namespace Example.Tests;

/// <summary>
/// Tests for the <see cref="ExampleClass"/> class.
/// </summary>
public class ExampleClassTests
{
  /// <summary>
  /// Test that the <see cref="ExampleClass"/> class is not null
  /// </summary>
  [Fact]
  public void Test1()
  {
    // Arrange
    var exampleClass = new ExampleClass();

    // Act & Assert
    Assert.NotNull(exampleClass);
  }
}

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
}

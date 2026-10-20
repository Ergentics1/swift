//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension BinaryFloatingPoint where Self.RawSignificand: FixedWidthInteger {

  /// Returns a random value within the specified range, using the given
  /// generator as a source for randomness.
  ///
  /// Use this method to generate a floating-point value within a specific
  /// range when you are using a custom random number generator. This example
  /// creates three new values in the range `10.0 ..< 20.0`.
  ///
  ///     for _ in 1...3 {
  ///         print(Double.random(in: 10.0 ..< 20.0, using: &myGenerator))
  ///     }
  ///     // Prints "18.1900709259179"
  ///     // Prints "14.2286325689993"
  ///     // Prints "13.1485686260762"
  ///
  /// The `random(in:using:)` static method chooses a random value from a
  /// continuous uniform distribution in `range`, and then converts that value
  /// to the nearest representable value in this type. Depending on the size
  /// and span of `range`, some concrete values may be represented more
  /// frequently than others.
  ///
  /// - Note: The algorithm used to create random values may change in a future
  ///   version of Swift. If you're passing a generator that results in the
  ///   same sequence of floating-point values each time you run your program,
  ///   that sequence may change when your program is compiled using a
  ///   different version of Swift.
  ///
  /// - Parameters:
  ///   - range: The range in which to create a random value.
  ///     `range` must be finite and non-empty.
  ///   - generator: The random number generator to use when creating the
  ///     new random value.
  /// - Returns: A random value within the bounds of `range`.
  @inlinable
  public static func random<T: RandomNumberGenerator>(
    in range: Range<Self>,
    using generator: inout T
  ) -> Self {
    _precondition(
      !range.isEmpty,
      "Can't get random value with an empty range"
    )
    _precondition(
      range.lowerBound.isFinite && range.upperBound.isFinite,
      "There is no uniform distribution on an infinite range"
    )
    let rand: Self.RawSignificand
    if Self.RawSignificand.bitWidth == Self.significandBitCount + 1 {
      rand = generator.next()
    } else {
      let significandCount = Self.significandBitCount + 1
      let maxSignificand: Self.RawSignificand = 1 << significandCount
      // Rather than use .next(upperBound:), which has to work with arbitrary
      // upper bounds, and therefore does extra work to avoid bias, we can take
      // a shortcut because we know that maxSignificand is a power of two.
      rand = generator.next() & (maxSignificand - 1)
    }
    let unitRandom = Self.init(rand) * (Self.ulpOfOne / 2)
    let delta = range.upperBound - range.lowerBound
    if delta.isFinite {
      let randFloat = delta * unitRandom + range.lowerBound
      if randFloat == range.upperBound {
        return Self.random(in: range, using: &generator)
      }
      return randFloat
    }
    // The bounds are finite, but their difference overflows (e.g. the
    // range is -greatestFiniteMagnitude..<greatestFiniteMagnitude).
    // Halving a floating-point value is exact, and so is doubling it,
    // so sample in the halved range, whose width cannot overflow, and
    // scale the result back up.
    let halfDelta = range.upperBound / 2 - range.lowerBound / 2
    let halfRandom = halfDelta * unitRandom + range.lowerBound / 2
    let randFloat = halfRandom * 2
    if randFloat == range.upperBound {
      return Self.random(in: range, using: &generator)
    }
    return randFloat
  }

  /// Returns a random value within the specified range.
  ///
  /// Use this method to generate a floating-point value within a specific
  /// range. This example creates three new values in the range
  /// `10.0 ..< 20.0`.
  ///
  ///     for _ in 1...3 {
  ///         print(Double.random(in: 10.0 ..< 20.0))
  ///     }
  ///     // Prints "18.1900709259179"
  ///     // Prints "14.2286325689993"
  ///     // Prints "13.1485686260762"
  ///
  /// The `random()` static method chooses a random value from a continuous
  /// uniform distribution in `range`, and then converts that value to the
  /// nearest representable value in this type. Depending on the size and span
  /// of `range`, some concrete values may be represented more frequently than
  /// others.
  ///
  /// This method is equivalent to calling `random(in:using:)`, passing in the
  /// system's default random generator.
  ///
  /// - Parameter range: The range in which to create a random value.
  ///   `range` must be finite and non-empty.
  /// - Returns: A random value within the bounds of `range`.
  @inlinable
  public static func random(in range: Range<Self>) -> Self {
    var g = SystemRandomNumberGenerator()
    return Self.random(in: range, using: &g)
  }
  
  /// Returns a random value within the specified range, using the given
  /// generator as a source for randomness.
  ///
  /// Use this method to generate a floating-point value within a specific
  /// range when you are using a custom random number generator. This example
  /// creates three new values in the range `10.0 ... 20.0`.
  ///
  ///     for _ in 1...3 {
  ///         print(Double.random(in: 10.0 ... 20.0, using: &myGenerator))
  ///     }
  ///     // Prints "18.1900709259179"
  ///     // Prints "14.2286325689993"
  ///     // Prints "13.1485686260762"
  ///
  /// The `random(in:using:)` static method chooses a random value from a
  /// continuous uniform distribution in `range`, and then converts that value
  /// to the nearest representable value in this type. Depending on the size
  /// and span of `range`, some concrete values may be represented more
  /// frequently than others.
  ///
  /// - Note: The algorithm used to create random values may change in a future
  ///   version of Swift. If you're passing a generator that results in the
  ///   same sequence of floating-point values each time you run your program,
  ///   that sequence may change when your program is compiled using a
  ///   different version of Swift.
  ///
  /// - Parameters:
  ///   - range: The range in which to create a random value. Must be finite.
  ///   - generator: The random number generator to use when creating the
  ///     new random value.
  /// - Returns: A random value within the bounds of `range`.
  @inlinable
  public static func random<T: RandomNumberGenerator>(
    in range: ClosedRange<Self>,
    using generator: inout T
  ) -> Self {
    _precondition(
      !range.isEmpty,
      "Can't get random value with an empty range"
    )
    _precondition(
      range.lowerBound.isFinite && range.upperBound.isFinite,
      "There is no uniform distribution on an infinite range"
    )
    let rand: Self.RawSignificand
    if Self.RawSignificand.bitWidth == Self.significandBitCount + 1 {
      rand = generator.next()
      let tmp: UInt8 = generator.next() & 1
      if rand == Self.RawSignificand.max && tmp == 1 {
        return range.upperBound
      }
    } else {
      let significandCount = Self.significandBitCount + 1
      let maxSignificand: Self.RawSignificand = 1 << significandCount
      rand = generator.next(upperBound: maxSignificand + 1)
      if rand == maxSignificand {
        return range.upperBound
      }
    }
    let unitRandom = Self.init(rand) * (Self.ulpOfOne / 2)
    let delta = range.upperBound - range.lowerBound
    if delta.isFinite {
      return delta * unitRandom + range.lowerBound
    }
    // The bounds are finite, but their difference overflows (e.g. the
    // range is -greatestFiniteMagnitude...greatestFiniteMagnitude).
    // Halving a floating-point value is exact, and so is doubling it,
    // so sample in the halved range, whose width cannot overflow, and
    // scale the result back up.
    let halfDelta = range.upperBound / 2 - range.lowerBound / 2
    let halfRandom = halfDelta * unitRandom + range.lowerBound / 2
    return halfRandom * 2
  }
  
  /// Returns a random value within the specified range.
  ///
  /// Use this method to generate a floating-point value within a specific
  /// range. This example creates three new values in the range
  /// `10.0 ... 20.0`.
  ///
  ///     for _ in 1...3 {
  ///         print(Double.random(in: 10.0 ... 20.0))
  ///     }
  ///     // Prints "18.1900709259179"
  ///     // Prints "14.2286325689993"
  ///     // Prints "13.1485686260762"
  ///
  /// The `random()` static method chooses a random value from a continuous
  /// uniform distribution in `range`, and then converts that value to the
  /// nearest representable value in this type. Depending on the size and span
  /// of `range`, some concrete values may be represented more frequently than
  /// others.
  ///
  /// This method is equivalent to calling `random(in:using:)`, passing in the
  /// system's default random generator.
  ///
  /// - Parameter range: The range in which to create a random value. Must be finite.
  /// - Returns: A random value within the bounds of `range`.
  @inlinable
  public static func random(in range: ClosedRange<Self>) -> Self {
    var g = SystemRandomNumberGenerator()
    return Self.random(in: range, using: &g)
  }
}

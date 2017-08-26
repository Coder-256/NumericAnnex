//
//  PRNG.swift
//  NumericAnnex
//
//  Created by Xiaodi Wu on 5/15/17.
//

#if os(Linux)
import Glibc
#else
import Security
#endif

/// A pseudo-random number generator (PRNG).
///
/// Reference types that conform to `PRNG` are infinite sequences of
/// pseudo-random elements. Protocol extension methods iterate over such a
/// sequence as necessary to generate pseudo-random values from the desired
/// distribution.
///
/// Considerations for Conforming Types
/// -----------------------------------
///
/// For clarity to end users, custom PRNGs may be implemented in an extension to
/// `Random`. For instance, the `xoroshiro128+` algorithm is implemented in a
/// final class named `Random.Xoroshiro`.
///
/// The static methods `_entropy(_:)` and `_entropy(_:count:)` return
/// cryptographically secure random bytes that may be useful for seeding your
/// custom PRNG. However, these methods may return `nil` if the requested number
/// of random bytes is not available, and they are not recommended as a routine
/// source of random data.
///
/// Adding Other Probability Distributions
/// --------------------------------------
///
/// Many built-in protocol extension methods make use of the primitive,
/// overloaded method `_random(_:bitCount:)`. You may wish to use the same
/// method in new protocol extension methods that return pseudo-random
/// values from other probability distributions.
///
/// The method `_random(_:bitCount:)` generates uniformly distributed binary
/// floating-point values in the half-open range [0, 1) with a precision of
/// either `bitCount` or the significand bit count of the floating-point type,
/// whichever is less. Additionally, this method generates uniformly distributed
/// unsigned integers in the half-open range [0, 2 ** _x_), where ** is the
/// exponentiation operator and _x_ is the lesser of `bitCount` and the bit
/// width of the integer type.
///
/// For end users, however, the recommended spelling for a uniformly distributed
/// numeric value is `uniform()`; that method is overloaded to permit custom
/// minimum and maximum values for the uniform distribution.
public protocol PRNG : class, IteratorProtocol, Sequence
where Element : FixedWidthInteger & UnsignedInteger,
  SubSequence : Sequence,
  Element == SubSequence.Element {
  /// A type that can represent the internal state of the pseudo-random number
  /// generator.
  associatedtype State

  /// The internal state of the pseudo-random number generator.
  var state: State { get set }

  /// Creates a pseudo-random number generator with the given internal state.
  ///
  /// - Parameters:
  ///   - state: The value to be used as the generator's internal state.
  init(state: State)

  /// Creates a pseudo-random number generator with an internal state seeded
  /// using cryptographically secure random bytes.
  ///
  /// If cryptographically secure random bytes are unavailable, the result is
  /// `nil`.
  init?()
  
  /// The maximum value that may be generated by the pseudo-random number
  /// generator.
  static var max: Element { get }

  /// The minimum value that may be generated by the pseudo-random number
  /// generator.
  static var min: Element { get }
}

extension PRNG {
  /// The maximum value that may be generated by the pseudo-random number
  /// generator (default implementation: `Element.max`).
  public static var max: Element { return Element.max }

  /// The minimum value that may be generated by the pseudo-random number
  /// generator (default implementation: `Element.min`).
  public static var min: Element { return Element.min }

  /// The number of pseudo-random bits available from a value generated by the
  /// pseudo-random number generator.
  public static var _randomBitWidth: Int {
    let difference = Self.max - Self.min
    guard difference < Element.max else { return Element.bitWidth }
    return Element.bitWidth - (difference + 1).leadingZeroBitCount - 1
  }

  /// Returns a value filled with data from a source of cryptographically secure
  /// random bytes, or `nil` if a sufficient number of cryptographically secure
  /// random bytes is unavailable.
  public static func _entropy<
    T : FixedWidthInteger & UnsignedInteger
  >(_: T.Type = T.self) -> T? {
    let size = MemoryLayout<T>.size
    var value = T()
#if os(Linux)
    // Read from `urandom`.
    // https://sockpuppet.org/blog/2014/02/25/safely-generate-random-numbers/
    guard let file = fopen("/dev/urandom", "rb") else { return nil }
    defer { fclose(file) }
    let read = fread(&value, size, 1, file)
    guard read == 1 else { return nil }
#else
    // Sandboxing can make `urandom` unavailable.
    let result = withUnsafeMutableBytes(of: &value) { ptr -> Int32 in
      let bytes = ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
      return SecRandomCopyBytes(nil, size, bytes)
    }
    guard result == errSecSuccess else { return nil }
#endif
    return value
  }

  /// Returns an array of `count` values filled with data from a source of
  /// cryptographically secure random bytes, or `nil` if a sufficient number of
  /// cryptographically secure random bytes is unavailable.
  public static func _entropy<
    T : FixedWidthInteger & UnsignedInteger
  >(_: T.Type = T.self, count: Int) -> [T]? {
    let stride = MemoryLayout<T>.stride
    var value = [T](repeating: 0, count: count)
#if os(Linux)
    guard let file = fopen("/dev/urandom", "rb") else { return nil }
    defer { fclose(file) }
    let read = fread(&value, stride, count, file)
    guard read == count else { return nil }
#else
    let result = value.withUnsafeMutableBytes { ptr -> Int32 in
      let bytes = ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
      return SecRandomCopyBytes(nil, stride * count, bytes)
    }
    guard result == errSecSuccess else { return nil }
#endif
    return value
  }
}

extension PRNG {
  /// Generates a pseudo-random unsigned integer of type `T` in the range from 0
  /// to `2 ** min(bitCount, T.bitWidth)` (exclusive), where `**` is the
  /// exponentiation operator.
  public func _random<T : FixedWidthInteger & UnsignedInteger>(
    _: T.Type = T.self, bitCount: Int = T.bitWidth
  ) -> T {
    let randomBitWidth = Self._randomBitWidth
    let bitCount = Swift.min(bitCount, T.bitWidth)
    if T.bitWidth == Element.bitWidth &&
      randomBitWidth == Element.bitWidth &&
      bitCount == T.bitWidth {
      // It is an awkward way of spelling `next()`, but it is necessary.
      guard let next = first(where: { _ in true }) else { fatalError() }
      return T(truncatingIfNeeded: next)
    }

    let (quotient, remainder) =
      bitCount.quotientAndRemainder(dividingBy: randomBitWidth)
    let max = (Element.max &>> (Element.bitWidth - randomBitWidth)) + Self.min
    var temporary = 0 as T
    // Call `next()` at least `quotient` times.
    for i in 0..<quotient {
      guard let next = first(where: { $0 <= max }) else { fatalError() }
      temporary += T(truncatingIfNeeded: next) &<< (randomBitWidth * i)
    }
    // If `remainder != 0`, call `next()` at least one more time.
    if remainder != 0 {
      guard let next = first(where: { $0 <= max }) else { fatalError() }
      let mask = Element.max &>> (Element.bitWidth - remainder)
      temporary +=
        T(truncatingIfNeeded: next & mask) &<< (randomBitWidth * quotient)
    }
    return temporary
  }

  /// Generates a pseudo-random unsigned integer of type `T` in the range from
  /// `a` through `b` (inclusive) from the discrete uniform distribution.
  public func uniform<T : FixedWidthInteger & UnsignedInteger>(
    _: T.Type = T.self, a: T, b: T
  ) -> T {
    precondition(
      b >= a,
      "Discrete uniform distribution parameter b should not be less than a"
    )
    guard a != b else { return a }

    let difference = b - a
    guard difference < T.max else {
      return _random() + a
    }
    let bitCount = T.bitWidth - difference.leadingZeroBitCount
    var temporary: T
    repeat {
      temporary = _random(bitCount: bitCount)
    } while temporary > difference
    return temporary + a
  }

  /// Generates a pseudo-random unsigned integer of type `T` in the range from
  /// `T.min` through `T.max` (inclusive) from the discrete uniform
  /// distribution.
  @_transparent // @_inlineable
  public func uniform<T : FixedWidthInteger & UnsignedInteger>(
    _: T.Type = T.self
  ) -> T {
    return uniform(a: T.min, b: T.max)
  }

  /// Generates a sequence of `count` pseudo-random unsigned integers of type
  /// `T` in the range from `a` through `b` (inclusive) from the discrete
  /// uniform distribution.
  @_transparent // @_inlineable
  public func uniform<T : FixedWidthInteger & UnsignedInteger>(
    _: T.Type = T.self, a: T, b: T, count: Int
  ) -> UnfoldSequence<T, Int> {
    precondition(count >= 0, "Element count should be non-negative")
    return sequence(state: 0) { (state: inout Int) -> T? in
      state += 1
      return state > count ? nil : self.uniform(a: a, b: b)
    }
  }

  /// Generates a sequence of `count` pseudo-random unsigned integers of type
  /// `T` in the range from `T.min` through `T.max` (inclusive) from the
  /// discrete uniform distribution.
  @_transparent // @_inlineable
  public func uniform<T : FixedWidthInteger & UnsignedInteger>(
    _: T.Type = T.self, count: Int
  ) -> UnfoldSequence<T, Int> {
    return uniform(a: T.min, b: T.max, count: count)
  }

  /// Generates a pseudo-random signed integer of type `T` in the range from `a`
  /// through `b` (inclusive) from the discrete uniform distribution.
  public func uniform<T : FixedWidthInteger & SignedInteger>(
    _: T.Type = T.self, a: T, b: T
  ) -> T where T.Magnitude : FixedWidthInteger & UnsignedInteger {
    precondition(
      b >= a,
      "Discrete uniform distribution parameter b should not be less than a"
    )
    guard a != b else { return a }

    let test = a.signum() < 0
    let difference = test
      ? (b.signum() < 0 ? a.magnitude - b.magnitude : b.magnitude + a.magnitude)
      : b.magnitude - a.magnitude
    guard difference < T.Magnitude.max else {
      return test ? T(_random() - a.magnitude) : T(_random() + a.magnitude)
    }
    let bitCount = T.Magnitude.bitWidth - difference.leadingZeroBitCount
    var temporary: T.Magnitude
    repeat {
      temporary = _random(bitCount: bitCount)
    } while temporary > difference
    return test ? T(temporary - a.magnitude) : T(temporary + a.magnitude)
  }

  /// Generates a pseudo-random signed integer of type `T` in the range from
  /// `T.min` through `T.max` (inclusive) from the discrete uniform
  /// distribution.
  @_transparent // @_inlineable
  public func uniform<T : FixedWidthInteger & SignedInteger>(
    _: T.Type = T.self
  ) -> T where T.Magnitude : FixedWidthInteger & UnsignedInteger {
    return uniform(a: T.min, b: T.max)
  }

  /// Generates a sequence of `count` pseudo-random signed integers of type `T`
  /// in the range from `a` through `b` (inclusive) from the discrete uniform
  /// distribution.
  @_transparent // @_inlineable
  public func uniform<T : FixedWidthInteger & SignedInteger>(
    _: T.Type = T.self, a: T, b: T, count: Int
  ) -> UnfoldSequence<T, Int>
  where T.Magnitude : FixedWidthInteger & UnsignedInteger {
    precondition(count >= 0, "Element count should be non-negative")
    return sequence(state: 0) { (state: inout Int) -> T? in
      state += 1
      return state > count ? nil : self.uniform(a: a, b: b)
    }
  }

  /// Generates a sequence of `count` pseudo-random signed integers of type `T`
  /// in the range from `T.min` through `T.max` (inclusive) from the discrete
  /// uniform distribution.
  @_transparent // @_inlineable
  public func uniform<T : FixedWidthInteger & SignedInteger>(
    _: T.Type = T.self, count: Int
  ) -> UnfoldSequence<T, Int>
  where T.Magnitude : FixedWidthInteger & UnsignedInteger {
    return uniform(a: T.min, b: T.max, count: count)
  }
}

// FIXME: If `FloatingPoint.init(_: FixedWidthInteger)` is added
// then it becomes possible to remove the constraint `Element == UInt64`.

extension PRNG where Element == UInt64 {
  /// Generates a pseudo-random binary floating-point value of type `T` in the
  /// range from 0 to 1 (exclusive) with `min(bitCount, T.significandBitCount)`
  /// bits of precision.
  public func _random<T : BinaryFloatingPoint>(
    _: T.Type = T.self, bitCount: Int = T.significandBitCount
  ) -> T {
    let bitCount = Swift.min(bitCount, T.significandBitCount)
    let (quotient, remainder) =
      bitCount.quotientAndRemainder(dividingBy: Self._randomBitWidth)
    let k = Swift.max(1, remainder == 0 ? quotient : quotient + 1)
    let step = T(Self.max - Self.min)
    let initial = (0 as T, 1 as T)
    // Call `next()` exactly `k` times.
    let (dividend, divisor) = prefix(k).reduce(initial) { partial, next in
      let x = partial.0 + T(next - Self.min) * partial.1
      let y = partial.1 + step * partial.1
      return (x, y)
    }
    return dividend / divisor
  }

  /// Generates a pseudo-random binary floating-point value of type `T` in the
  /// range from `a` to `b` (exclusive) from the uniform distribution.
  public func uniform<T : BinaryFloatingPoint>(
    _: T.Type = T.self, a: T, b: T
  ) -> T {
    precondition(
      b > a,
      "Uniform distribution parameter b should be greater than a"
    )
    var temporary: T
    repeat {
      temporary = (b - a) * _random() + a
    } while temporary == b
    return temporary
  }

  /// Generates a pseudo-random binary floating-point value of type `T` in the
  /// range from 0 to 1 (exclusive) from the uniform distribution.
  @_transparent // @_inlineable
  public func uniform<T : BinaryFloatingPoint>(_: T.Type = T.self) -> T {
    return uniform(a: 0, b: 1)
  }

  /// Generates a sequence of `count` pseudo-random binary floating-point values
  /// of type `T` in the range from `a` to `b` (exclusive) from the uniform
  /// distribution.
  @_transparent // @_inlineable
  public func uniform<T : BinaryFloatingPoint>(
    _: T.Type = T.self, a: T, b: T, count: Int
  ) -> UnfoldSequence<T, Int> {
    precondition(count >= 0, "Element count should be non-negative")
    return sequence(state: 0) { (state: inout Int) -> T? in
      state += 1
      return state > count ? nil : self.uniform(a: a, b: b)
    }
  }

  /// Generates a sequence of `count` pseudo-random binary floating-point values
  /// of type `T` in the range from 0 to 1 (exclusive) from the uniform
  /// distribution.
  @_transparent // @_inlineable
  public func uniform<T : BinaryFloatingPoint>(
    _: T.Type = T.self, count: Int
  ) -> UnfoldSequence<T, Int> {
    return uniform(a: 0, b: 1, count: count)
  }
}

#if false
extension PRNG where Element == UInt64 {
  /* public */ func bernoulli<T : BinaryFloatingPoint>(
    _: Bool.Type = Bool.self, p: T
  ) -> Bool {
    precondition(
      p >= 0 && p <= 1,
      "Bernoulli distribution parameter p should be between zero and one"
    )
    var temporary: T
    repeat {
      temporary = _random()
    } while temporary == 1
    return temporary < p
  }

  @_transparent // @_inlineable
  /* public */ func bernoulli(_: Bool.Type = Bool.self) -> Bool {
    return bernoulli(p: 0.5)
  }

  @_transparent // @_inlineable
  /* public */ func bernoulli<T : BinaryFloatingPoint>(
    _: Bool.Type = Bool.self, p: T, count: Int
  ) -> UnfoldSequence<Bool, Int> {
    precondition(count >= 0, "Element count should be non-negative")
    return sequence(state: 0) { (state: inout Int) -> Bool? in
      state += 1
      return state > count ? nil : self.bernoulli(p: p)
    }
  }

  @_transparent // @_inlineable
  /* public */ func bernoulli(
    _: Bool.Type = Bool.self, count: Int
  ) -> UnfoldSequence<Bool, Int> {
    return bernoulli(p: 0.5, count: count)
  }

  /* public */ func exponential<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self, lambda: T
  ) -> T {
    precondition(
      lambda > 0 && lambda < .infinity,
      "Exponential distribution parameter lambda should be positive and finite"
    )
    var temporary: T
    repeat {
      temporary = -.log(1 - _random()) / lambda
    } while temporary == .infinity
    return temporary
  }

  @_transparent // @_inlineable
  /* public */ func exponential<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self
  ) -> T {
    return exponential(lambda: 1)
  }

  @_transparent // @_inlineable
  /* public */ func exponential<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self, lambda: T, count: Int
  ) -> UnfoldSequence<T, Int> {
    precondition(count >= 0, "Element count should be non-negative")
    return sequence(state: 0) { (state: inout Int) -> T? in
      state += 1
      return state > count ? nil : self.exponential(lambda: lambda)
    }
  }

  @_transparent // @_inlineable
  /* public */ func exponential<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self, count: Int
  ) -> UnfoldSequence<T, Int> {
    return exponential(lambda: 1, count: count)
  }
  
  /* public */ func weibull<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self, lambda: T, kappa: T
  ) -> T {
    precondition(
      lambda > 0 && lambda < .infinity && kappa > 0 && kappa < .infinity,
      "Weibull distribution parameters should be positive and finite"
    )
    var temporary: T
    repeat {
      temporary = lambda * .pow(-.log(1 - _random()), 1 / kappa)
    } while temporary == .infinity
    return temporary
  }

  @_transparent // @_inlineable
  /* public */ func weibull<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self
  ) -> T {
    return weibull(lambda: 1, kappa: 1)
  }

  @_transparent // @_inlineable
  /* public */ func weibull<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self, lambda: T, kappa: T, count: Int
  ) -> UnfoldSequence<T, Int> {
    precondition(count >= 0, "Element count should be non-negative")
    return sequence(state: 0) { (state: inout Int) -> T? in
      state += 1
      return state > count ? nil : self.weibull(lambda: lambda, kappa: kappa)
    }
  }

  @_transparent // @_inlineable
  /* public */ func weibull<T : BinaryFloatingPoint & Real>(
    _: T.Type = T.self, count: Int
  ) -> UnfoldSequence<T, Int> {
    return weibull(lambda: 1, kappa: 1, count: count)
  }
}
#endif

# NumericAnnex

NumericAnnex supplements the numeric facilities provided in the Swift standard
library.


## Features

- [x] `BinaryInteger` exponentiation, greatest common divisor, and least common
      multiple functions.
- [x] `Math`, a protocol for types providing square root, cube root, and
      elementary transcendental functions.
- [x] `FloatingPointMath`, a protocol for floating point types providing a
      selection of special functions.
- [x] `Complex`, a value type to represent complex values in Cartesian form.
- [x] `Rational`, a value type to represent rational values, which supports
      division by zero.

> Note: This project is in the early stages of development and is not
> production-ready at this time.


## Requirements

NumericAnnex now requires the latest development (master) branch of Swift or a
recent development snapshot that includes the revised numeric protocols. It
requires either `Darwin` or `Glibc` for transcendental functions provided by the
C standard library.


## Installation

After NumericAnnex has been cloned or downloaded locally, build the library by
invoking `swift build`, or run tests with `swift test`. An Xcode project can be
generated by invoking `swift package generate-xcodeproj`.

[Swift Package Manager](https://swift.org/package-manager/) can also be used to
add the package as a dependency for your own project. See Swift documentation
for details.


## Basic Usage

```swift
import NumericAnnex

var x: Ratio = 1 / 4
// Ratio is a type alias for Rational<Int>.

print(x.reciprocal())
// Prints "4".

x *= 8
print(x + x)
// Prints "4".

x = Ratio(Float.phi) // Golden ratio.
print(x)
// Prints "13573053/8388608".

var z: Complex64 = 42 * .i
// Complex64 is a type alias for Complex<Float>.

print(Complex.sqrt(z))
// Prints "4.58258 + 4.58258i".

z = .pi + .i * .log(2 - .sqrt(3))
print(Complex.cos(z).real)
// Prints "-2.0".
```


## Documentation

All public protocols, types, and functions have been carefully documented in
comments.

The project adheres to many design patterns found in the Swift standard library.
For example, `Math` types provide methods such as `cubeRoot()` and `tangent()`
just as `FloatingPoint` types provide methods such as `squareRoot()`.

No free functions are declared in this library unless they overload existing
ones in the Swift standard library. Instead, functions such as `cbrt(_:)` and
`tan(_:)` are provided as static members. This avoids collisions with C standard
library functions that you may wish to use. It also promotes clarity at the call
site when the result of a complex operation differs from that of its real
counterpart (e.g., `Complex128.cbrt(-8) != -2`).


## Future Directions

- [ ] Add more tests
- [ ] Design and implement `BigInt`
- [ ] Design and implement `Random`


## License

All original work is released under the MIT license. See
[LICENSE](https://github.com/xwu/NumericAnnex/blob/master/LICENSE) for details.

Portions of the complex square root and elementary transcendental functions use
checks for special values adapted from libc++. Code in libc++ is dual-licensed
under the MIT and UIUC/NCSA licenses.

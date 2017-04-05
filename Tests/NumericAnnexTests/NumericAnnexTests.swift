import XCTest
@testable import NumericAnnex

class NumericAnnexTests: XCTestCase {
  let pzpz = Complex(real: +0.0, imaginary: +0.0)
  let pznz = Complex(real: +0.0, imaginary: -0.0)
  let nzpz = Complex(real: -0.0, imaginary: +0.0)
  let nznz = Complex(real: -0.0, imaginary: -0.0)

  let pipi = Complex(real: Double.infinity, imaginary: .infinity)
  let pini = Complex(real: Double.infinity, imaginary: -.infinity)
  let nipi = Complex(real: -Double.infinity, imaginary: .infinity)
  let nini = Complex(real: -Double.infinity, imaginary: -.infinity)

  let pipz = Complex(real: .infinity, imaginary: +0.0)
  let nipz = Complex(real: -.infinity, imaginary: +0.0)
  let pinz = Complex(real: .infinity, imaginary: -0.0)
  let ninz = Complex(real: -.infinity, imaginary: -0.0)

  let pxpi = Complex(real: +2.0, imaginary: .infinity)
  let pxni = Complex(real: +2.0, imaginary: -.infinity)
  let pipy = Complex(real: .infinity, imaginary: +2.0)
  let nipy = Complex(real: -.infinity, imaginary: +2.0)

  let pzpn = Complex(real: +0.0, imaginary: .nan)
  let nzpn = Complex(real: -0.0, imaginary: .nan)
  let pnpz = Complex(real: .nan, imaginary: +0.0)
  let pnnz = Complex(real: .nan, imaginary: -0.0)

  let pxpn = Complex(real: +2.0, imaginary: .nan)
  let nxpn = Complex(real: -2.0, imaginary: .nan)
  let pnpy = Complex(real: .nan, imaginary: +2.0)
  let pnny = Complex(real: .nan, imaginary: -2.0)

  let pipn = Complex(real: Double.infinity, imaginary: .nan)
  let nipn = Complex(real: -Double.infinity, imaginary: .nan)
  let pnpi = Complex(real: Double.nan, imaginary: .infinity)
  let pnni = Complex(real: Double.nan, imaginary: -.infinity)

  let pnpn = Complex(real: Double.nan, imaginary: .nan)

  func testComplexAddition() {
    let foo: Complex128 = 1.0 + 2.0 * .i
    let bar: Complex128 = 2 + 4 * .i
    XCTAssertEqual(foo + bar, 3 + 6 * .i)

    /*
    let baz: Complex<Float> = 2 + 4 * .i
    let boo = 3 + (6 as Float).i
    */
  }

  func testComplexDivision() {
    let a = 3 + 2 * Complex128.i
    let b = 4 - 3 * Complex128.i
    let c = a / b
    XCTAssertEqual(c.real, 6/25)
    XCTAssertEqual(c.imaginary, 17/25)
  }

  func testComplexSquareRoot() {
    let a: Complex128 = -4
    XCTAssertEqual(Complex.sqrt(a), 2 * .i)
    let b: Complex128 = 4
    XCTAssertEqual(Complex.sqrt(b), 2)

    // Test special values.
    var result: Complex128
    result = Complex.sqrt(pzpz)
    XCTAssertTrue(result.isZero)
    XCTAssertTrue(result.real.sign == .plus)
    XCTAssertTrue(result.imaginary.sign == .plus)

    result = Complex.sqrt(nzpz)
    XCTAssertTrue(result.isZero)
    XCTAssertTrue(result.real.sign == .plus)
    XCTAssertTrue(result.imaginary.sign == .plus)

    result = Complex.sqrt(pxpi)
    XCTAssertEqual(result.real, .infinity)
    XCTAssertEqual(result.imaginary, .infinity)

    result = Complex.sqrt(pnpi)
    XCTAssertEqual(result.real, .infinity)
    XCTAssertEqual(result.imaginary, .infinity)

    result = Complex.sqrt(pxpn)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isNaN)

    result = Complex.sqrt(nipy)
    XCTAssertEqual(result.real, 0)
    XCTAssertTrue(result.real.sign == .plus)
    XCTAssertEqual(result.imaginary, .infinity)

    result = Complex.sqrt(pipy)
    XCTAssertEqual(result.real, .infinity)
    XCTAssertEqual(result.imaginary, 0)
    XCTAssertTrue(result.imaginary.sign == .plus)

    result = Complex.sqrt(nipn)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isInfinite)
    // The sign of the imaginary part is unspecified.

    result = Complex.sqrt(pipn)
    XCTAssertEqual(result.real, .infinity)
    XCTAssertTrue(result.imaginary.isNaN)

    result = Complex.sqrt(pnpy)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isNaN)

    result = Complex.sqrt(pnpn)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isNaN)
  }

  func testComplexExponentiation() {
    let a = Complex(real: Double.log(42))
    let b = Complex.exp(a)
    XCTAssertEqualWithAccuracy(b.real, 42, accuracy: 0.00000000000001)

    let i: Complex128 = .i
    let actual = i.power(of: i)
    let expected = Double.exp(-Double.pi / 2)
    XCTAssertEqual(actual.real, expected)
    XCTAssertEqual(actual.imaginary, 0)

    // Test special values.
    var result: Complex128
    result = Complex.exp(pzpz)
    XCTAssertEqual(result.real, 1)
    XCTAssertEqual(result.imaginary, 0)
    XCTAssertTrue(result.imaginary.sign == .plus)

    result = Complex.exp(nzpz)
    XCTAssertEqual(result.real, 1)
    XCTAssertEqual(result.imaginary, 0)
    XCTAssertTrue(result.imaginary.sign == .plus)

    result = Complex.exp(pxpi)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isNaN)
    // In C++, FE_INVALID is raised.

    result = Complex.exp(pxpn)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isNaN)

    result = Complex.exp(pipz)
    XCTAssertTrue(result == pipz)
    XCTAssertTrue(result.imaginary.sign == .plus)

    result = Complex.exp(nipy)
    XCTAssertEqual(result.real, 0)
    // TODO: ...
     
    result = Complex.exp(pipy)
    XCTAssertTrue(result.real.isInfinite)
    // TODO: ...

    result = Complex.exp(nipi)
    XCTAssertTrue(result.isZero)
    // The signs of zero are unspecified.

    result = Complex.exp(pipi)
    XCTAssertTrue(result.real.isInfinite)
    // The sign of the real part is unspecified.
    XCTAssertTrue(result.imaginary.isNaN)
    // In C++, FE_INVALID is raised.

    result = Complex.exp(nipn)
    XCTAssertTrue(result.isZero)
    // The signs of zero are unspecified.

    result = Complex.exp(pipn)
    XCTAssertTrue(result.real.isInfinite)
    // The sign of the real part is unspecified.
    XCTAssertTrue(result.imaginary.isNaN)

    result = Complex.exp(pnpz)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertEqual(result.imaginary, pnpz.imaginary)

    result = Complex.exp(pnpy)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isNaN)

    result = Complex.exp(pnpn)
    XCTAssertTrue(result.real.isNaN)
    XCTAssertTrue(result.imaginary.isNaN)
  }

  static var allTests = [
    ("testComplexAddition", testComplexAddition),
    ("testComplexDivision", testComplexDivision),
    ("testComplexSquareRoot", testComplexSquareRoot),
    ("testComplexExponentiation", testComplexExponentiation),
  ]
}
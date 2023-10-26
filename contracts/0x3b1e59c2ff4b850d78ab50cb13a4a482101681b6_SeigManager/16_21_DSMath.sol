// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DSMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }
  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }
  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint x, uint y) internal pure returns (uint z) {
    return x <= y ? x : y;
  }
  function max(uint x, uint y) internal pure returns (uint z) {
    return x >= y ? x : y;
  }
  function imin(int x, int y) internal pure returns (int z) {
    return x <= y ? x : y;
  }
  function imax(int x, int y) internal pure returns (int z) {
    return x >= y ? x : y;
  }

  uint constant WAD_ = 10 ** 18;
  uint constant RAY_ = 10 ** 27;

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), WAD_ / 2) / WAD_;
  }
  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), RAY_ / 2) / RAY_;
  }
  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, WAD_), y / 2) / y;
  }
  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, RAY_), y / 2) / y;
  }

  function wmul2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, y) / WAD_;
  }
  function rmul2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, y) / RAY_;
  }
  function wdiv2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, WAD_) / y;
  }
  function rdiv2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, RAY_) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //  x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //  floor[(n-1) / 2] = floor[n / 2].
  //
  function wpow(uint x, uint n) internal pure returns (uint z) {
    z = n % 2 != 0 ? x : WAD_;

    for (n /= 2; n != 0; n /= 2) {
      x = wmul(x, x);

      if (n % 2 != 0) {
        z = wmul(z, x);
      }
    }
  }

  function rpow(uint x, uint n) internal pure returns (uint z) {
    z = n % 2 != 0 ? x : RAY_;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}
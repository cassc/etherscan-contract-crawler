// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
import "./CoderConstants.sol";

uint256 constant TenThousand = 1e4;
uint256 constant OneGwei = 1e9;
uint256 constant OneEth = 1e18;

library Math {
  function avg(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = (a & b) + (a ^ b) / 2;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = ternary(a < b, a, b);
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = ternary(a < b, b, a);
  }

  function subMinZero(uint256 a, uint256 b) internal pure returns (uint256 c) {
    unchecked {
      c = ternary(a > b, a - b, 0);
    }
  }

  function uncheckedMulBipsUp(uint256 x, uint256 bips) internal pure returns (uint256 y) {
    assembly {
      let numerator := mul(x, bips)
      y := mul(iszero(iszero(numerator)), add(div(sub(numerator, 1), TenThousand), 1))
    }
  }

  function uncheckedMulBipsUpWithMultiplier(
    uint256 x,
    uint256 bips,
    uint8 multiplier
  ) internal pure returns (uint256) {
    return uncheckedMulBipsUp(x, (bips * multiplier) / 100);
  }

  // Equivalent to ceil((x)e-4)
  function uncheckedDivUpE4(uint256 x) internal pure returns (uint256 y) {
    assembly {
      y := add(div(sub(x, 1), TenThousand), 1)
    }
  }

  // Equivalent to ceil((x)e-9)
  function uncheckedDivUpE9(uint256 x) internal pure returns (uint256 y) {
    assembly {
      y := add(div(sub(x, 1), OneGwei), 1)
    }
  }

  function mulBips(uint256 n, uint256 bips) internal pure returns (uint256 result) {
    result = (n * bips) / TenThousand;
  }

  function ternary(
    bool condition,
    uint256 valueIfTrue,
    uint256 valueIfFalse
  ) internal pure returns (uint256 c) {
    assembly {
      c := add(valueIfFalse, mul(condition, sub(valueIfTrue, valueIfFalse)))
    }
  }
}
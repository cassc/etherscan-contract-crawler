// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {SafeCast} from "@timeswap-labs/v2-library/contracts/SafeCast.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";
import {FullMath} from "@timeswap-labs/v2-library/contracts/FullMath.sol";

library PriceConversion {
  using SafeCast for uint256;

  function convertTsToUni(uint256 strike) internal pure returns (uint160 sqrtRatioX96) {
    if (strike <= type(uint192).max) return sqrtRatioX96 = Math.sqrt(strike << 64, false).toUint160();

    (uint256 value0, uint256 value1) = FullMath.mul512(strike, 1 << 64);
    sqrtRatioX96 = FullMath.sqrt512(value0, value1, false).toUint160();
  }
}
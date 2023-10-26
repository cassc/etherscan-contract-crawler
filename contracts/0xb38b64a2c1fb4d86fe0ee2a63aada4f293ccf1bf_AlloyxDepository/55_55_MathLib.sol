//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { FullMath } from "./FullMath.sol";

library MathLib {

    function fromDecimalToDecimal(uint256 amount, uint8 inDecimals, uint8 outDecimals) internal pure returns (uint256) {
        return amount * 10 ** outDecimals / 10 ** inDecimals;
    }

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    // solhint-disable-next-line func-name-mixedcase
    function formatX10_18ToX96(
    // solhint-disable-next-line var-name-mixedcase
        uint256 valueX10_18
    ) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    // solhint-disable-next-line func-name-mixedcase
    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }
}
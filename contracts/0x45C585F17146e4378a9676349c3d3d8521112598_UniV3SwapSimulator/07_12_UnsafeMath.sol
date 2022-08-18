// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/UnsafeMath.sol
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}
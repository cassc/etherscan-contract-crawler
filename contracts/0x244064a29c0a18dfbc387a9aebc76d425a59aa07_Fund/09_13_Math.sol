// SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

library Math {
    uint256 internal constant ZOC = 1e4;

    /**
     * @dev Multiply 2 numbers where at least one is a zoc, return product in original units of the other number.
     */
    function zocmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked {
            z /= ZOC;
        }
    }

    // Below is WAD math from solmate's FixedPointMathLib.
    // https://github.com/Rari-Capital/solmate/blob/c8278b3cb948cffda3f1de5a401858035f262060/src/utils/FixedPointMathLib.sol

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    // For tokens with 6 decimals like USDC, these scale by 1e6 (one million).
    function mulMilDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, 1e6); // Equivalent to (x * y) / 1e6 rounded down.
    }

    function divMilDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, 1e6, y); // Equivalent to (x * 1e6) / y rounded down.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }
}
// SPDX-License-Identifier: Apache-2.0
// solhint-disable const-name-snakecase

pragma solidity =0.8.9;

/**
 * @title WadRayMath library
 * @author Voltz, matching an interface and terminology used by Aave for consistency
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/
library WadRayMath {
    enum Mode {
        WAD_MODE,
        RAY_MODE
    }

    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;

    uint256 public constant HALF_WAD = WAD / 2;
    uint256 public constant HALF_RAY = RAY / 2;

    uint256 public constant WAD_RAY_RATIO = RAY / WAD;
    uint256 internal constant HALF_RATIO = WAD_RAY_RATIO / 2;

    // Multiplies two values in WAD_MODE or RAY_MODE, rounding up
    function _mul(
        uint256 a,
        uint256 b,
        Mode m
    ) private pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return
            (a * b + (m == Mode.RAY_MODE ? HALF_RAY : HALF_WAD)) /
            (m == Mode.RAY_MODE ? RAY : WAD);
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b, Mode.WAD_MODE);
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b, Mode.RAY_MODE);
    }

    // Divides two values in WAD_MODE or RAY_MODE, rounding up
    function _div(
        uint256 a,
        uint256 b,
        Mode m
    ) private pure returns (uint256) {
        require(b != 0, "DIV0");
        uint256 halfB = b / 2;

        return (a * (m == Mode.RAY_MODE ? RAY : WAD) + halfB) / b;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, Mode.WAD_MODE);
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, Mode.RAY_MODE);
    }

    /**
     * @dev Scales a value in WAD up to a value in RAY
     * @param a WAD value
     * @return a, scaled up to a value in RAY
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        return result;
    }

    /**
     * @dev Scales a value in RAY down to a value in WAD
     * @param a RAY value
     * @return a, scaled down to a value in WAD (rounded up to the nearest WAD)
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 result = a / WAD_RAY_RATIO;

        if (a % WAD_RAY_RATIO >= HALF_RATIO) {
            result += 1;
        }

        return result;
    }
}
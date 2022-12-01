// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/
library MathUtils {
    uint256 public constant VERSION = 1;

    uint256 internal constant WAD_UNIT = 18;
    uint256 internal constant RAY_UNIT = 27;
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;
    uint256 public constant HALF_WAD = WAD / 2;
    uint256 public constant HALF_RAY = RAY / 2;


    /**
     * @notice Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_WAD) / b, "MathUtils: overflow");

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @notice Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, "MathUtils: overflow");

        return (a * WAD + halfB) / b;
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_RAY) / b, "MathUtils: overflow");

        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, "MathUtils: overflow");

        return (a * RAY + halfB) / b;
    }

    /**
     * @notice Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, "MathUtils: overflow");

        return result / WAD_RAY_RATIO;
    }

    /**
     * @notice Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, "MathUtils: overflow");
        return result;
    }

    /**
     * @notice Converts unit to wad
     * @param self Value
     * @param unit Value's unit
     * @return value converted in wad
     **/
    function unitToWad(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD_UNIT) return self;

        if (unit < WAD_UNIT) {
            return self * 10**(WAD_UNIT - unit);
        } else {
            return self / 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * 10**(RAY_UNIT -unit);
        } else {
            return self / 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * int256(10**(RAY_UNIT -unit));
        } else {
            return self / int256(10**(unit - RAY_UNIT));
        }
    }

    /**
     * @notice Converts wad to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function wadToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD) return self;

        if (unit < WAD_UNIT) {
            return self / 10**(WAD_UNIT - unit);
        } else {
            return self * 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / 10**(RAY_UNIT - unit);
        } else {
            return self * 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / int256(10**(RAY_UNIT - unit));
        } else {
            return self * int256(10**(unit - RAY_UNIT));
        }
    }

    function abs(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(a * (-1));
        } else {
            return uint256(a);
        }
    }
}
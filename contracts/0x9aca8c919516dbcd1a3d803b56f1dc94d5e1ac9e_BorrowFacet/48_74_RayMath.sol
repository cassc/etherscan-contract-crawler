// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {RAY} from "../DataStructure/Global.sol";
import {Ray} from "../DataStructure/Objects.sol";

/// @notice Manipulates fixed-point unsigned decimals numbers
/// @dev all uints are considered integers (no wad)
library RayMath {
    // ~~~ calculus ~~~ //

    /// @notice `a` plus `b`
    /// @return result
    function add(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) + Ray.unwrap(b));
    }

    /// @notice `a` minus `b`
    /// @return result
    function sub(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) - Ray.unwrap(b));
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap((Ray.unwrap(a) * Ray.unwrap(b)) / RAY);
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(Ray a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) * b);
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(uint256 a, Ray b) internal pure returns (uint256) {
        return (a * Ray.unwrap(b)) / RAY;
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap((Ray.unwrap(a) * RAY) / Ray.unwrap(b));
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(Ray a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) / b);
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(uint256 a, Ray b) internal pure returns (uint256) {
        return (a * RAY) / Ray.unwrap(b);
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(uint256 a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap((a * RAY) / b);
    }

    // ~~~ comparisons ~~~ //

    /// @notice is `a` less than `b`
    /// @return result
    function lt(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) < Ray.unwrap(b);
    }

    /// @notice is `a` greater than `b`
    /// @return result
    function gt(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) > Ray.unwrap(b);
    }

    /// @notice is `a` greater or equal to `b`
    /// @return result
    function gte(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) >= Ray.unwrap(b);
    }

    /// @notice is `a` equal to `b`
    /// @return result
    function eq(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) == Ray.unwrap(b);
    }

    // ~~~ uint256 method ~~~ //

    /// @notice highest value among `a` and `b`
    /// @return maximum
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
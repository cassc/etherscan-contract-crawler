pragma solidity ^0.8.10;

import {ICurvePoolMinimal} from "./ICurvePoolMinimal.sol";

/// @dev This interface is incomplete and may be invalid for some of Curve pools.
interface ICurveMetapoolMinimal is ICurvePoolMinimal {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
}
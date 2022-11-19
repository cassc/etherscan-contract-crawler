// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

/// @title Abbreviated Curve.fi interface for 3pool to allow use of USDC / USDT
/// @author mfw78 <[email protected]>
/// @dev Refer https://github.com/curvefi/curve-contract/tree/master/contracts/pools/3pool
interface I3PoolCurve {
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function coins(uint256 arg0) external view returns (address);
}
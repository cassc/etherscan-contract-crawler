// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICurveMetaPoolLike {
    // solhint-disable-next-line func-name-mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external returns (uint256);
    // solhint-disable-next-line func-name-mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
}
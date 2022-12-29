// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICurvePoolLike128 {
    // solhint-disable-next-line func-name-mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;
    // solhint-disable-next-line func-name-mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}
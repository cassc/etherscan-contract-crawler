// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external payable;
}
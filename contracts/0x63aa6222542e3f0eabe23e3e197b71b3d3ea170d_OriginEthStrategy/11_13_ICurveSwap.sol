// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurveSwap{
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external payable;
    function exchange(uint256 i, uint256 j, uint256 _dx, uint256 _min_dy, bool used_eth, address receiver) external payable;
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns(uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Ipool {
    function exchange(int128, int128, uint256, uint256) external returns(uint256);
    function get_dy(int128, int128, uint256) external returns(uint256);
    
}
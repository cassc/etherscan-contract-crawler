// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IAmm {
    function read_user_tick_numbers(address user) external view returns(int256[2] memory);
    function active_band() external view returns(int256);
    
}
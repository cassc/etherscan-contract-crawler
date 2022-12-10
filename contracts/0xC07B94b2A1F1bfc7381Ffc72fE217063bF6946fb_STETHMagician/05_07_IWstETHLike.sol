// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWstETHLike {
    function unwrap(uint256 _wstETHAmount) external returns (uint256 stETHAmount);
    function wrap(uint256 _stETHAmount) external returns (uint256 wstETHAmount);
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
}
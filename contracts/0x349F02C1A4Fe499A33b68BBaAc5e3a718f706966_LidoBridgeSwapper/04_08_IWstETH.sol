//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IWstETH {
    function stETH() external returns (address);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}
//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


interface IWstEth{

    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHShares) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function tokensPerStEth() external view returns (uint256);
}
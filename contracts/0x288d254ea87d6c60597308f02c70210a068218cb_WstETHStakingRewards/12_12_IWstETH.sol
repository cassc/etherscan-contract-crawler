// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWstETH is IERC20 {
    function getWstETHByStETH(uint _stETHAmount) external view returns (uint _wstETHAmount);
    function getStETHByWstETH(uint _wstETHAmount) external view returns (uint _stETHAmount);
    function stETH() external view returns (address);
    
    function wrap(uint256 _stETHAmount) external returns (uint _receivedWstETHAmount);
    function unwrap(uint256 _wstETHAmount) external returns (uint _receivedStETHAmount);
}
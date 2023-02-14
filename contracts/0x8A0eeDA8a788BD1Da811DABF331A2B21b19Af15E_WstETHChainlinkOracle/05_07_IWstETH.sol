// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IERC20} from "IERC20.sol";

interface IWstETH is IERC20 {
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function stEthPerToken() external view returns (uint256);
    function stETH() external view returns (address);
}
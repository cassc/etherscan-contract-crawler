// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWstETH is IERC20 {
    function unwrap(uint256 _wstETHAmount) external returns (uint256 _stETHAmount);

    function wrap(uint256 _stETHAmount) external returns (uint256 _wstETHAmount);

    function getStETHByWstETH(uint256 _wstETHAmount) external returns (uint256 _stETHAmount);

    function getWstETHByStETH(uint256 _stETHAmount) external returns (uint256 _wstETHAmount);
}
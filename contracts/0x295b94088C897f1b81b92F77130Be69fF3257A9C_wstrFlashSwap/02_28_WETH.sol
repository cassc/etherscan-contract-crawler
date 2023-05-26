// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import { IERC20 as ERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface WETHInterface {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint wad) external;
}

abstract contract WETH is WETHInterface {}
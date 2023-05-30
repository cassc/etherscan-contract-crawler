// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Hotpot V3 基金份额代币接口定义
interface IHotPotV3FundERC20 is IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// SPDX-License-Identifier: GPL-2.0-or-later
// IWETH interface via Uniswap, modified
pragma solidity ^0.8.15;

import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20MetadataUpgradeable {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title UXDTimelockController
/// @notice Timelock for UXD governance contract
/// @dev This serves as the executor for governance proposals. 
/// This also serves as the treasury address for governance proposals
contract UXDTimelockController is TimelockController, ReentrancyGuard {

    ///         Errors
    error TimelockERC20ApprovalFailed(address token, address to, uint256 amount);
    error TimelockCallerNotSelf(address caller);

    using SafeERC20 for IERC20;
    
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert TimelockCallerNotSelf(msg.sender);
        }
        _;
    }

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) {}

    /////////////////////////////////////////////////////////////
    ///                 Value transfers
    /////////////////////////////////////////////////////////////

    /// @notice Transfer ETH out of this contract
    /// @dev Can only be called by governance.
    /// @param to The address to transfer ETH to
    /// @param amount The amount to transfer
    function transferETH(address payable to, uint256 amount) external onlySelf nonReentrant {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send ETH");
    }

    /// @notice Approve the transfer of an ERC20 token out of this contract.
    /// @dev Can only be called by governance.
    /// @param token The ERC20 token address.
    /// @param spender The address allowed to spend.
    /// @param amount The amount to transfer.
    function approveERC20(address token, address spender, uint256 amount) external onlySelf {
        if (!(IERC20(token).approve(spender, amount))) {
            revert TimelockERC20ApprovalFailed(token, spender, amount);
        }
    }

    /// @notice Transfer ERC20 tokens out of this contract
    /// @dev Can only be called by governance.
    /// @param token The ERC20 token address.
    /// @param to The address to transfer token to
    /// @param amount The amount to transfer
    function transferERC20(address token, address to, uint256 amount) external onlySelf nonReentrant  {
        IERC20(token).safeTransfer(to, amount);
    }
}
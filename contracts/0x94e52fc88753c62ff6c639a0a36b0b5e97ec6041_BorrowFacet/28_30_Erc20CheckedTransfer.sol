// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ERC20TransferFailed} from "../DataStructure/Errors.sol";

/// @notice library to safely transfer ERC20 tokens, including not entirely compliant tokens like BNB and USDT
/// @dev avoids bugs due to tokens not following the erc20 standard by not returning a boolean
///     or by reverting on 0 amount transfers. Does not support fee on transfer tokens
library Erc20CheckedTransfer {
    using SafeERC20 for IERC20;

    /// @notice executes only if amount is greater than zero
    /// @param amount amount to check
    modifier skipZeroAmount(uint256 amount) {
        if (amount > 0) {
            _;
        }
    }

    /// @notice safely transfers
    /// @param currency ERC20 to transfer
    /// @param from sender
    /// @param to recipient
    /// @param amount amount to transfer
    function checkedTransferFrom(
        IERC20 currency,
        address from,
        address to,
        uint256 amount
    ) internal skipZeroAmount(amount) {
        currency.safeTransferFrom(from, to, amount);
    }

    /// @notice safely transfers
    /// @param currency ERC20 to transfer
    /// @param to recipient
    /// @param amount amount to transfer
    function checkedTransfer(IERC20 currency, address to, uint256 amount) internal skipZeroAmount(amount) {
        currency.safeTransfer(to, amount);
    }
}
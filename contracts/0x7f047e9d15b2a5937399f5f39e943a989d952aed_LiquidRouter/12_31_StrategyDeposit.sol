// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {IVault} from "src/interfaces/IVault.sol";
import {ERC20, TokenUtils, Constants} from "src/common/TokenUtils.sol";

/// @title StrategyDeposit
/// @notice Enables to deposit to a Liquid Locker Strategy.
abstract contract StrategyDeposit {
    /// @notice Deposits to a Liquid Locker Strategy.
    /// @param vault Vault address.
    /// @param token Token address.
    /// @param underlyingAmount Amount of token to deposit.
    /// @param recipient Recipient address.
    /// @param earn Whether to deposit assets to Curve Gauge or not. Socialize deposits to save gas.
    function deposit(address vault, address token, uint256 underlyingAmount, address recipient, bool earn)
        external
        payable
    {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, token);

        TokenUtils._approve(token, vault);
        IVault(vault).deposit(recipient, underlyingAmount, earn);
    }
}
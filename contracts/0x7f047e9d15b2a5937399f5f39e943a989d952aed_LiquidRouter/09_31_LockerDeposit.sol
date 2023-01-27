// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {ILocker} from "src/interfaces/ILocker.sol";
import {TokenUtils, Constants} from "src/common/TokenUtils.sol";

/// @title LockerDeposit
/// @notice Enables to deposit to a Liquid Locker.
abstract contract LockerDeposit {
    /// @notice Deposits to a Liquid Locker.
    /// @param locker Locker address.
    /// @param token Token address.
    /// @param lock Whether to lock the token.
    /// @param stake Whether to stake the token.
    /// @param underlyingAmount Amount of token to deposit.
    /// @param recipient Recipient address.
    function deposit(address locker, address token, bool lock, bool stake, uint256 underlyingAmount, address recipient)
        external
        payable
    {
        if (recipient == Constants.MSG_SENDER || stake) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, token);

        TokenUtils._approve(token, locker);
        ILocker(locker).deposit(underlyingAmount, lock, stake, recipient);
    }
}
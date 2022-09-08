// SPDX-License-Identifier: MIT OR Apache-2.0

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

pragma solidity ^0.7.6;

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the pendingWithdrawals for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is OwnableUpgradeable {
    /// @dev Tracks the amount of ETH that is stored in escrow for future withdrawal.
    mapping(address => uint256) internal pendingWithdrawals;

    /**
     * @notice Emitted when escrowed funds are withdrawn.
     * @param executor The account which has withdrawn ETH, either the owner or an Admin.
     * @param owner The owner whose ETH has been withdrawn from.
     * @param recipient The address where the funds were transfered to.
     * @param amount The amount of ETH which has been withdrawn.
     */
    event PendingWithdrawalCompleted(
        address indexed executor,
        address indexed owner,
        address recipient,
        uint256 amount
    );

    /**
     * @notice Emitted when escrowed funds are deposite into pending Withdrawals.
     * @param owner The owner whose ETH has been deposit.
     * @param amount The amount of ETH which has been deposit.
     */
    event PendingWithdrawalDeposit(address indexed owner, uint256 amount);

    /**
     * @dev Attempt to send a user or contract ETH and
     * if it fails store the amount owned for later withdrawal .
     *  @dev This function doesn't check for reentrancy issues so be careful when invoking
     */
    function _sendValueWithFallbackWithdraw(
        address payable user,
        uint256 amount,
        uint256 gasLimit
    ) internal {
        if (amount == 0) {
            return;
        }
        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
        if (!success) {
            // Store the funds that failed to send for the user pendingWithdrawals list
            pendingWithdrawals[user] += amount;
            emit PendingWithdrawalDeposit(user, amount);
        }
    }

    function _withdrawTo(address from, address payable recipient) internal {
        uint256 pendingAmount = pendingWithdrawals[from];
        if (pendingAmount != 0) {
            // No reentray is possible
            pendingWithdrawals[from] = 0;
            (bool success, ) = recipient.call{ value: pendingAmount }("");
            require(success, "withdrawal failed");
            emit PendingWithdrawalCompleted(msg.sender, from, recipient, pendingAmount);
        }
    }

    /**
     * @notice Allows owner to widthawl pending funds (on failed sale send).
     * @param recipient The address to sent the locked funds to.
     */
    function withdrawTo(address payable recipient) public {
        _withdrawTo(msg.sender, recipient);
    }

    /**
     * @notice Allows Enigma to widthawl pending funds (on failed sale send) on behalf of a user.
     * This should only be used for extreme cases when the user has prove unintended funds locked up.
     * @param fundsOwner The user address holding the pending funds.
     * @param recipient The address to sent the locked funds to.
     */
    function adminWithdrawTo(address fundsOwner, address payable recipient) external onlyOwner {
        _withdrawTo(fundsOwner, recipient);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;
}
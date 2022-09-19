// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";

abstract contract BlockMelonPullPayment is
    PullPaymentUpgradeable,
    ReentrancyGuardUpgradeable
{
    function __BlockMelonPullPayment_init() internal onlyInitializing {
        __PullPayment_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev See {PullPaymentUpgradeable-withdrawPayments}
     * @dev This version of `withdrawPayments` adds protection against reentrancy attacks
     */
    function withdrawPayments(address payable payee)
        public
        override
        nonReentrant
    {
        super.withdrawPayments(payee);
    }

    /**
     * @dev Sends `amount` to the address of `recipient`, if `amount` > 0
     * If transfer was unsuccessful then save `amount` as a deposit which can be withdrawn by `withdrawPayments`
     */
    function _sendValueToRecipient(address payable recipient, uint256 amount)
        internal
    {
        if (0 == amount) {
            return;
        }
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            _asyncTransfer(recipient, amount);
        }
    }

    uint256[50] private __gap;
}
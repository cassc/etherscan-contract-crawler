// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "../../../deps/OwnableUpgradeable.sol";

/**
 * @title WithdrawableUpgradeable
 * @author Cyborg Labs, LLC
 *
 * @dev Supports ETH withdrawals by the owner.
 */
abstract contract WithdrawableUpgradeable is
    OwnableUpgradeable
{
    event Withdrawal(
        address recipient,
        uint256 balance
    );

    function __Withdrawable_init()
        internal
        onlyInitializing
    {
        __Ownable_init();
    }

    function __Withdrawable_init_unchained()
        internal
        onlyInitializing
    {}

    function withdrawTo(
        address recipient
    )
        external
        onlyOwner
        returns (uint256)
    {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
        emit Withdrawal(recipient, balance);
        return balance;
    }
}
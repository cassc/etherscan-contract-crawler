// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import {Shared} from "../libraries/Shared.sol";
import {PaymentSplitter} from "../abstracts/PaymentSplitter.sol";

contract PaymentSplitterFacet is PaymentSplitter {
    // =============================================================
    //                   Custom Functions
    // =============================================================
    /**
     * @dev Adds a payee to the contract.
     * @param account The address of the payee.
     * @param shares_ The number of shares to assign to the payee.
     */
    function addPayee(address account, uint256 shares_) public onlyOwner {
        Shared._addPayee(account, shares_);
    }
}
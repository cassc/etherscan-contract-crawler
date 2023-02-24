// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./external/PaymentSplitter.sol";

/// @title Canis Royalty
/// @author Think and Dev
contract Royalty is Ownable, PaymentSplitter {
    event PayeeRemove(address account, uint256 shares);

    /**
     * @notice Init contract
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * @param payees addresses of payees
     * @param shares values of shares
     */
    constructor(address[] memory payees, uint256[] memory shares) PaymentSplitter(payees, shares) {}

    /**
     * @dev Remove a payee to the contract.
     * @param indexPayee The index of payee to remove it.
     * @param account The address of the payee to remove.
     */
    function removePayee(uint256 indexPayee, address account) external onlyOwner {
        require(account != address(0), "Royalty: account is the zero address");
        require(indexPayee < _payees.length, "Royalty: indexPayee not exist in payees");
        require(_payees[indexPayee] == account, "Royalty: account is not the same as account in the index");

        //delete moving the last element to not leave a gap
        _payees[indexPayee] = _payees[_payees.length - 1];
        _payees.pop();
        //delete mapping
        uint256 oldShare = _shares[account];
        delete _shares[account];
        _totalShares = _totalShares - oldShare;

        emit PayeeRemove(account, oldShare);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares The number of shares owned by the payee.
     */
    function addPayee(address account, uint256 shares) external onlyOwner {
        _addPayee(account, shares);
    }
}
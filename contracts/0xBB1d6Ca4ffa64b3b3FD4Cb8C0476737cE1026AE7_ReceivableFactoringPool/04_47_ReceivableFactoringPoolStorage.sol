// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BaseStructs as BS} from "./libraries/BaseStructs.sol";

contract ReceivableFactoringPoolStorage {
    /// mapping from wallet address to the receivable supplied by this wallet
    mapping(address => BS.ReceivableInfo) internal _receivableInfoMapping;

    /// mapping from the keccak256 hash of the payment event emitting address and its unique
    /// payment ID to a boolean. Used for preventing duplicate payment processing calls.
    mapping(bytes32 => bool) internal _processedPaymentIds;
    /// mapping from the keccak256 hash of the receivableAddress and receivableParam to
    /// the borrower address. This is needed for us to locate the borrower using
    /// the received receivable asset.
    mapping(bytes32 => address) internal _receivableOwnershipMapping;

    /// list of outlier payments that require manual review before processing
    mapping(bytes32 => BS.FlagedPaymentRecord) internal _paymentsToBeReviewed;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[99] private __gap;
}
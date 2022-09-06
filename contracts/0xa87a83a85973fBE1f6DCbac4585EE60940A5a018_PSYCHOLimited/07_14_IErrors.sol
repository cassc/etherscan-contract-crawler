// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Errors interface
 */
interface IErrors {
    error TransferToZeroAddress();

    error NonApprovedNonOwner();

    error ApproveOwnerAsOperator();

    error TransferFromNonOwner();

    error CallerIsNonContractOwner();

    error InactiveGenesis();

    error ExceedsGenesisLimit();

    error NonValidSelection();

    error PriceNotMet();

    error TransferToNonERC721Receiver();
}
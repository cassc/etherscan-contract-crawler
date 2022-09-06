// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IMint {
    error InvalidProof();
    error InvalidETHAmount();
    error AlreadyClaimed();
    error AlreadyMinted();
    error ClaimingNotActive();
    error PrivateSaleNotActive();
    error TransferToNonERC721ReceiverImplementer();
    error InvalidTransferToZeroAddress();
    error MintZeroTokenId();
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAutographNFT {
    error InvalidSigner();
    error NotContractOwner();
    error AlreadyMinted();
    error MintClosed();
    error AlreadySigned();
    error NonExistentToken();
    error SoldOut();
    error InconsistentDates();

    event MetadataUpdate(uint256 _tokenId);
}
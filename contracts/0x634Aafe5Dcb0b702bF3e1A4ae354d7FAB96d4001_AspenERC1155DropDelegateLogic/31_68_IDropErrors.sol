// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IDropErrorsV0 {
    error InvalidPermission();
    error InvalidIndex();
    error NothingToReveal();
    error NotTrustedForwarder();
    error InvalidTimetamp();
    error CrossedLimitLazyMintedTokens();
    error CrossedLimitMinTokenIdGreaterThanMaxTotalSupply();
    error CrossedLimitQuantityPerTransaction();
    error CrossedLimitMaxClaimableSupply();
    error CrossedLimitMaxTotalSupply();
    error CrossedLimitMaxWalletClaimCount();
    error InvalidPrice();
    error InvalidPaymentAmount();
    error InvalidQuantity();
    error InvalidTime();
    error InvalidGating();
    error InvalidMerkleProof();
    error InvalidMaxQuantityProof();
    error MaxBps();
    error ClaimPaused();
    error NoActiveMintCondition();
    error TermsNotAccepted(address caller, string termsURI, uint8 acceptedVersion);
    error BaseURIEmpty();
    error FrozenTokenMetadata(uint256 tokenId);
    error InvalidTokenId(uint256 tokenId);
    error InvalidNoOfTokenIds();
    error InvalidPhaseId(bytes32 phaseId);
    error SignatureVerificationFailed();
}
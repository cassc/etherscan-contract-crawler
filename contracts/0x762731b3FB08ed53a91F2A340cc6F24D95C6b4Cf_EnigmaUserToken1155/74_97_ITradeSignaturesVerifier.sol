// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

enum AssetType { ERC1155, ERC721 }

struct PlatformFees {
    address assetAddress;
    uint256 tokenId;
    uint8 buyerFeePermille;
    uint8 sellerFeePermille;
    bytes signature;
}

struct WithdrawRequest {
    uint256 nonce; // Unique id for this withdraw authorization
    address assetAddress;
    AssetType assetType;
    uint256 tokenId;
    uint256 quantity;
}

abstract contract ITradeSignaturesVerifier {
    /**
     * @notice Internal function to verify a sign to mint tokens
     * Reverts if the sign verification fails.
     * @param platformFees Struct that has information about platform fees
     * @param authorizer address of the wallet that authorizes minters
     */
    function verifyPlatformFeesSignature(PlatformFees calldata platformFees, address authorizer) internal view virtual;

    /**
     * @notice Verifies the seller authorization to sell a token
     * @param seller address of the seller, should be the current owner of the token
     * @param tokenId id of the tokens to be sold
     * @param unitPrice price per token unit
     * @param paymentAssetAddress address of the ERC20 that is used to pay, ZERO_ADDRESS is used when
     * paying with ethers
     * @param assetAddress address of the NFT's contract
     * @param sellerFeePermille sellerFee that is authorized by the seller(this is used in order to
     * check that the platform does not unilaterally change the fee)
     * @param signature bytes that represent the signature
     */
    function verifySellerSignature(
        address seller,
        uint256 tokenId,
        uint256 unitPrice,
        address paymentAssetAddress,
        address assetAddress,
        uint8 sellerFeePermille,
        bytes memory signature
    ) internal view virtual;

    /**
     * @notice Verifies the custodial authorization for this withdraw for this assetOwner
     * @param assetCustodial current asset holder
     * @param assetOwner real asset owner address
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature bytes that represent the signature
     */
    function verifyWithdrawSignature(
        address assetCustodial,
        address assetOwner,
        WithdrawRequest memory wr,
        bytes memory signature
    ) internal view virtual;
}
// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./ISignableStructsBuyNow.sol";

/**
 * @title Interface to Verification of MetaTXs for BuyNows.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the interface to the two verifying functions
 *  for the structs defined in ISignableStructsBuyNow (BuyNowInput, AssetTransferResult),
 *  used within the BuyNow process, as well as to the function that verifies
 *  the seller signature agreeing to list the asset.
 *  Potential future changes in any of these signing methods can be handled by having
 *  the main contract redirect to a different verifier contract.
 */

interface IEIP712VerifierBuyNow is ISignableStructsBuyNow {
    /**
     * @notice Verifies that the provided BuyNowInput struct has been signed
     *  by the provided signer.
     * @param buyNowInp The provided BuyNowInput struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the
     *  provided signer having signed the input struct
     */
    function verifyBuyNow(
        BuyNowInput calldata buyNowInp,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    /**
     * @notice Verifies that the provided AssetTransferResult struct
     *  has been signed by the provided signer.
     * @param transferResult The provided AssetTransferResult struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the signer
     *  having signed the input struct
     */
    function verifyAssetTransferResult(
        AssetTransferResult calldata transferResult,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    /**
     * @notice Verifies the seller signature showing agreement 
     *  to list the asset as ruled by this explicit paymentId.
     * @dev To anticipate for future potential differences in verifiers for
     *  BuyNow/Auction listings, the interfaces to verifiers for both flows are 
     *  kept separate, accepting the entire respective structs as input.
     *  For the same reason, the interface declares the method as 'view', prepared
     *  to use EIP712 flows, even if the initial implementation can be 'pure'.
     * @param sellerSignature the signature of the seller agreeing to list the asset as ruled by
     *  this explicit paymentId
     * @param buyNowInp The provided BuyNowInput struct
     * @return Returns true if the seller signature is correct
     */
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BuyNowInput calldata buyNowInp
    ) external view returns (bool);
}
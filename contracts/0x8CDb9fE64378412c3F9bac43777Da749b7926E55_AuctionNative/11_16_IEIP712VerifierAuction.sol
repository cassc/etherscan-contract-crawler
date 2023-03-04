// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./ISignableStructsAuction.sol";

/**
 * @title Interface to Verification of MetaTXs for Auctions.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the interface to the verifying function
 *  for the struct defined in ISignableStructsAuction (BidInput),
 *  used in auction processes, as well as to the function that verifies
 *  the seller signature agreeing to list the asset.
 *  Potential future changes in any of these signing methods can be handled by having
 *  the main contract redirect to a different verifier contract.
 */

interface IEIP712VerifierAuction is ISignableStructsAuction {
    /**
     * @notice Verifies that the provided BidInput struct has been signed
     *  by the provided signer.
     * @param bidInput The provided BidInput struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the
     *  provided signer having signed the input struct
     */
    function verifyBid(
        BidInput calldata bidInput,
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
     * @param bidInput The provided BuyNowInput struct
     * @return Returns true if the seller signature is correct
     */
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BidInput calldata bidInput
    ) external view returns (bool);
}
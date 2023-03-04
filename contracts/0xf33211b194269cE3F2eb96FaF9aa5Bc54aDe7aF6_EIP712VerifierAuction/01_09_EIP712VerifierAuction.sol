// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./IEIP712VerifierAuction.sol";
import "../../buyNow/base/EIP712VerifierBuyNow.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Verification of MetaTXs for Auctions, that extends
 *  the verification for BuyNows inherited in EIP712VerifierBuyNow.
 * @author Freeverse.io, www.freeverse.io
 * @notice Full contract documentation in IEIP712VerifierAuction
 */

contract EIP712VerifierAuction is IEIP712VerifierAuction, EIP712VerifierBuyNow {
    using ECDSA for bytes32;
    bytes32 private constant _TYPEHASH_BID =
        keccak256(
            "BidInput(bytes32 paymentId,uint256 endsAt,uint256 bidAmount,uint256 feeBPS,uint256 universeId,uint256 deadline,address bidder,address seller)"
        );

    constructor(string memory name, string memory version) EIP712VerifierBuyNow(name, version) {}

    /// @inheritdoc IEIP712VerifierAuction
    function verifyBid(
        BidInput calldata bidInput,
        bytes calldata signature,
        address signer
    ) public view returns (bool) {
        address recoveredSigner = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH_BID, bidInput))
        ).recover(signature);
        return signer == recoveredSigner;
    }

    /// @inheritdoc IEIP712VerifierAuction
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BidInput calldata bidInput
    ) public pure returns (bool) {
        /*
         * @dev The sellerSignature is also required off-chain (in the L2) to initiate the listing;
         *  in the L2, 'paymentId' is basically the digest of all listing extended set of params,
         *  so in the current implementation, the code basically has to check that the seller signed 'paymentId'.
        */
        return bidInput.seller == bidInput.paymentId.toEthSignedMessageHash().recover(sellerSignature);
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * Represents the external interface of a marketplace contract.
 */
interface IPrimaryMarketplace {
    /**
     * Represents a transaction message sent by clients for purchasing a token.
     */
    struct TransactionMessage {
        //Information about the parties involved in the transaction.
        address payable paymentReceiver;
        address tokenReceiver;
        //Information about the value of the transaction.
        uint128 payment;
        uint128 commission;
        //Information about the token being purchased.
        address collection;
        uint128 tokenId;
        string tokenURI;
        //Information about the royalty of the token being purchased.
        address royaltyReceiver;
        uint16 royaltyNumerator;
        //Information about the signature of the transaction message.
        uint256 nonce;
    }

    /**
     * Purchases a token for a fixed price.
     *
     * Payable function.
     *
     * @param message The transaction message.
     * @param signature The signature of the transaction message.
     */
    function purchaseFixedPrice(
        TransactionMessage calldata message,
        bytes calldata signature
    ) external payable;

    /**
     * Sets the configurable validator address that will be used when verifying
     * signed transaction messages.
     *
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     */
    function setValidator(address validator_) external;

    /**
     * Emitted when a token is purchased for a fixed price.
     */
    event FixedPricePurchased(
        address paymentReceiver,
        address tokenReceiver,
        uint256 payment,
        address collection,
        uint256 tokenId
    );
}
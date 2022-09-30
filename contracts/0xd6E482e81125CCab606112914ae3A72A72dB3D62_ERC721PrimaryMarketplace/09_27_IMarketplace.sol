//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * Represents the external interface of a marketplace contract.
 */
interface IMarketplace {

    /**
     * Represents a transaction message sent by clients for purchasing a token.
     */
    struct TransactionMessage {
        address payable seller;
        address buyer;
        uint128 payment;
        address collection;
        uint128 tokenId;
        string tokenURI;
        uint256 tokenAmount;
        uint16 royaltyNumerator;
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
     * Sets the configurable commission numerator that will be used for
     * calculating the commission amount of a transaction.
     *
     * @param commissionNumerator_ The configurable commission numerator that
     *     will be used for calculating the commission amount of a transaction.
     */
    function setCommissionNumerator(
        uint16 commissionNumerator_
    ) external;

    /**
     * Sets the configurable maximum royalty numerator that will be used for
     * verifying the royalty numerator of a transaction.
     *
     * @param maxRoyaltyNumerator_ The configurable maximum royalty numerator
     *     that will be used for calculating the commission amount of a
     *     transaction.
     */
    function setMaxRoyaltyNumerator(
        uint16 maxRoyaltyNumerator_
    ) external;

    /**
     * Sets the configurable validator address that will be used when verifying
     * signed transaction messages.
     *
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     */
    function setValidator(
        address validator_
    ) external;

    /**
     * Emitted when a token is purchased for a fixed price.
     */
    event FixedPricePurchased(
        address seller,
        address buyer,
        address collection,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 payment
    );
}
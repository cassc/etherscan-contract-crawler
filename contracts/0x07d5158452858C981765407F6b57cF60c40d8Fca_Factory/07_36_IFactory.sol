//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * Represents the external interface of an ERC-721 factory.
 */
interface IFactory {
    /**
     * Represents a transaction message sent by clients for minting a collection.
     */
    struct TransactionMessage {
        uint256 transactionId;
        //Information about collection to be minted.
        string name;
        string symbol;
        //Information about the signature of the transaction message.
        uint256 nonce;
    }

    /**
     * Mints a new collection.
     *
     * Emits an ERC721CollectionMinted event after completion.
     *
     * @param message The transaction message.
     * @param signature The signature of the transaction message.
     */
    function mintCollection(
        TransactionMessage calldata message,
        bytes calldata signature
    ) external;


    /**
     * Sets the configurable validator address that will be used when verifying
     * signed transaction messages.
     *
     * @param validator_ The configurable validator address that will be used
     *     when verifying signed transaction messages.
     */
    function setValidator(address validator_) external;

    /**
     * Sets the configurable marketplace address.
     */
    function setMarketplace(address marketplace) external;


    event ERC721CollectionMinted(
        uint256 transactionId,
        string name, 
        string symbol, 
        address collection, 
        address creator
    );
}
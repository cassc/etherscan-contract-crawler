// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IPaymentTokenReader.sol";

interface IPaymentTokenRegistry is IPaymentTokenReader {
    struct PaymentTokenRecord {
        uint32 id;
        address token;
    }

    event PaymentTokenRecoredAdded(uint32 id, address token, address sender);
    event PaymentTokenRecoredRemoved(uint32 id, address token, address sender);

    event GlobalPaymentTokenAdded(uint32 id, address token, address sender);

    event GlobalPaymentTokenRemoved(uint32 id, address token, address sender);

    event CollectionPaymentTokenAdded(
        address collectionAddress,
        uint32 id,
        address token,
        address sender
    );

    event CollectionPaymentTokenRemoved(
        address collectionAddress,
        uint32 id,
        address token,
        address sender
    );

    /**
     * @dev get list of globally allowed payment tokens
     */
    function globalAllowedPaymentTokens()
        external
        view
        returns (PaymentTokenRecord[] memory);

    /**
     * @dev get list of allowed payment tokens for a collection
     * this doesn't include globally allowed ones
     */
    function allowedPaymentTokensOfCollection(
        address collectionAddress
    ) external view returns (PaymentTokenRecord[] memory);

    /**
     * @dev add payment tokens records
     */
    function addPaymentTokenRecord(address token) external;

    /**
     * @dev add globally allowed payment tokens
     */
    function addGlobalPaymentToken(uint32 id) external;

    /**
     * @dev remove globally allowed payment tokens
     */
    function removeGlobalPaymentToken(uint32 id) external;

    /**
     * @dev add allowed payment tokens to collection
     */
    function addCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external;

    /**
     * @dev remove allowed payment tokens from collection
     */
    function removeCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external;
}
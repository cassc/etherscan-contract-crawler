// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IPaymentTokenRegistry.sol";

contract PaymentTokenRegistry is IPaymentTokenRegistry, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint32 private _currentIncrementalId;
    mapping(uint32 => address) paymentTokenRecords;
    mapping(address => uint32) paymentTokenIds;

    EnumerableSet.UintSet private _globalPaymentTokenIds;
    mapping(address => EnumerableSet.UintSet)
        private _collectionPaymentTokenIds;

    /**
     * @dev See {IPaymentTokenRegistry-isAllowedPaymentToken}.
     */
    function isAllowedPaymentToken(
        address collectionAddress,
        uint32 paymentTokenId
    ) external view returns (bool) {
        return
            _globalPaymentTokenIds.contains(paymentTokenId) ||
            _collectionPaymentTokenIds[collectionAddress].contains(
                paymentTokenId
            );
    }

    /**
     * @dev See {IPaymentTokenRegistry-getPaymentTokenIdByAddress}.
     */
    function getPaymentTokenIdByAddress(
        address token
    ) external view returns (uint32) {
        return paymentTokenIds[token];
    }

    /**
     * @dev See {IPaymentTokenRegistry-getPaymentTokenAddressById}.
     */
    function getPaymentTokenAddressById(
        uint32 id
    ) external view returns (address) {
        return paymentTokenRecords[id];
    }

    /**
     * @dev See {IPaymentTokenRegistry-globalAllowedPaymentTokens}.
     */
    function globalAllowedPaymentTokens()
        external
        view
        returns (PaymentTokenRecord[] memory paymentTokens)
    {
        paymentTokens = new PaymentTokenRecord[](
            _globalPaymentTokenIds.length()
        );

        for (uint256 i; i < _globalPaymentTokenIds.length(); i++) {
            uint32 id = uint32(_globalPaymentTokenIds.at(i));
            paymentTokens[i] = PaymentTokenRecord(id, paymentTokenRecords[id]);
        }
    }

    /**
     * @dev See {IPaymentTokenRegistry-allowedPaymentTokensOfCollection}.
     */
    function allowedPaymentTokensOfCollection(
        address collectionAddress
    ) external view returns (PaymentTokenRecord[] memory paymentTokens) {
        uint256 tokenCount = _collectionPaymentTokenIds[collectionAddress]
            .length();
        paymentTokens = new PaymentTokenRecord[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            uint32 id = uint32(
                _collectionPaymentTokenIds[collectionAddress].at(i)
            );
            paymentTokens[i] = PaymentTokenRecord(id, paymentTokenRecords[id]);
        }
    }

    /**
     * @dev See {IPaymentTokenRegistry-addGlobalPaymentToken}.
     */
    function addPaymentTokenRecord(address token) external onlyOwner {
        require(
            paymentTokenIds[token] == 0,
            "PaymentTokenRegistry: token already exist"
        );

        _currentIncrementalId += 1;
        paymentTokenRecords[_currentIncrementalId] = token;
        paymentTokenIds[token] = _currentIncrementalId;

        emit PaymentTokenRecoredAdded(
            _currentIncrementalId,
            token,
            _msgSender()
        );
    }

    /**
     * @dev See {IPaymentTokenRegistry-addGlobalPaymentToken}.
     */
    function addGlobalPaymentToken(uint32 id) external onlyOwner {
        require(
            !_globalPaymentTokenIds.contains(id),
            "PaymentTokenRegistry: token already exist"
        );

        _globalPaymentTokenIds.add(id);

        emit GlobalPaymentTokenAdded(id, paymentTokenRecords[id], _msgSender());
    }

    /**
     * @dev See {IPaymentTokenRegistry-removeGlobalPaymentToken}.
     */
    function removeGlobalPaymentToken(uint32 id) external onlyOwner {
        require(
            _globalPaymentTokenIds.contains(id),
            "PaymentTokenRegistry: token doesn't exist"
        );

        _globalPaymentTokenIds.remove(id);

        emit GlobalPaymentTokenRemoved(
            id,
            paymentTokenRecords[id],
            _msgSender()
        );
    }

    /**
     * @dev See {IPaymentTokenRegistry-addCollectionPaymentToken}.
     */
    function addCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external onlyOwner {
        require(
            !_collectionPaymentTokenIds[collectionAddress].contains(id),
            "PaymentTokenRegistry: token already exist for this collection"
        );

        _collectionPaymentTokenIds[collectionAddress].add(id);

        emit CollectionPaymentTokenAdded(
            collectionAddress,
            id,
            paymentTokenRecords[id],
            _msgSender()
        );
    }

    /**
     * @dev See {IPaymentTokenRegistry-removeCollectionPaymentToken}.
     */
    function removeCollectionPaymentToken(
        address collectionAddress,
        uint32 id
    ) external onlyOwner {
        require(
            _collectionPaymentTokenIds[collectionAddress].contains(id),
            "PaymentTokenRegistry: token doesn't exist for this collection"
        );

        _collectionPaymentTokenIds[collectionAddress].remove(id);

        emit CollectionPaymentTokenRemoved(
            collectionAddress,
            id,
            paymentTokenRecords[id],
            _msgSender()
        );
    }
}
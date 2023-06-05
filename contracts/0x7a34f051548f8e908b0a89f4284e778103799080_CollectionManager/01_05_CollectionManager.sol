// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ICollectionManager} from "./interfaces/ICollectionManager.sol";

/**
 * @title CollectionManager
 * @notice It allows adding/removing collections for trading on the CryptoAvatars exchange.
 */
contract CollectionManager is ICollectionManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedCollections;

    event CollectionRemoved(address indexed collection);
    event CollectionWhitelisted(address indexed collection);

    /**
     * @notice Add a collection in the system
     * @param collection address of the collection to add
     */
    function addCollection(address collection) external override onlyOwner {
        require(!_whitelistedCollections.contains(collection), "Collection: Already whitelisted");
        _whitelistedCollections.add(collection);

        emit CollectionWhitelisted(collection);
    }

    /**
     * @notice Remove a collection from the system
     * @param collection address of the collection to remove
     */
    function removeCollection(address collection) external override onlyOwner {
        require(_whitelistedCollections.contains(collection), "Collection: Not whitelisted");
        _whitelistedCollections.remove(collection);

        emit CollectionRemoved(collection);
    }

    /**
     * @notice Returns if a collection is in the system
     * @param collection address of the collection
     */
    function isCollectionWhitelisted(address collection) external view override returns (bool) {
        return _whitelistedCollections.contains(collection);
    }

    /**
     * @notice View number of whitelisted collections
     */
    function viewCountWhitelistedCollections() external view override returns (uint256) {
        return _whitelistedCollections.length();
    }

    /**
     * @notice See whitelisted collections in the system
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewWhitelistedCollections(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedCollections.length() - cursor) {
            length = _whitelistedCollections.length() - cursor;
        }

        address[] memory whitelistedCollections = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedCollections[i] = _whitelistedCollections.at(cursor + i);
        }

        return (whitelistedCollections, cursor + length);
    }
}
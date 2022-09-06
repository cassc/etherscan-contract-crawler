// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferManagerSelector {
    event CollectionTransferManagerSet(
        address indexed collection,
        address indexed transferManager
    );

    event CollectionTransferManagerUnSet(address indexed collection);

    function setCollectionTransferManager(
        address collection,
        address transferManager
    ) external;

    function unSetCollectionTransferManager(address collection) external;

    function getTransferManager(address collection)
        external
        view
        returns (address);
}
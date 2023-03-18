// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IFactoryGovernedProxy {
    event CollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string baseURI,
        string name,
        string symbol,
        uint256 collectionLength
    );

    function emitCollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        uint256 collectionLength
    ) external;

    function setSporkProxy(address payable _sporkProxy) external;
}
// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IMetadataGovernedProxy {
    function initialize(address _implementation) external;

    function setSporkProxy(address payable _sporkProxy) external;

    function emitMetadataHashesUploaded(bytes4 batchId, uint256 numItems) external;

    function emitStartingIndexSet(bytes4 batchId, uint256 startingIndex) external;
}
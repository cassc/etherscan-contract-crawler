// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IMetadataStorage {
    // Getter functions
    //
    function getRequestIdsCount() external view returns (uint256);

    function getRequestIdByIndex(uint256 _index) external view returns (uint256);

    function getBatchIdsCount() external view returns (uint256);

    function getBatchIdByIndex(uint256 _index) external view returns (bytes4);

    function getRequestIdByBatchId(bytes4 _batchId) external view returns (uint256);

    function getBatchIdByRequestId(uint256 _requestId) external view returns (bytes4);

    function getStartingIndex(bytes4 _batchId) external view returns (uint256);

    function getMetadataHashesBatchLength(bytes4 _batchId) external view returns (uint256);

    function getMetadataHashByIndex(bytes4 _batchId, uint256 _index)
        external
        view
        returns (bytes32);

    // Setter functions
    //
    function pushRequestId(uint256 _requestId) external;

    function popRequestId() external;

    function setRequestIdAtIndex(uint256 _requestId, uint256 index) external;

    function pushBatchId(bytes4 _batchId) external;

    function popBatchId() external;

    function setBatchIdAtIndex(bytes4 _batchId, uint256 index) external;

    function setRequestIdByBatchId(uint256 _requestId, bytes4 _batchId) external;

    function setBatchIdByRequestId(bytes4 _batchId, uint256 _requestId) external;

    function setStartingIndex(bytes4 _batchId, uint256 _startingIndex) external;

    function setMetadataHashesBatch(bytes4 _batchId, bytes32[] calldata _metadataHashes) external;

    function pushMetadataHash(bytes4 _batchId, bytes32 _metadataHash) external;

    function popMetadataHash(bytes4 _batchId) external;

    function setMetadataHashAtIndex(
        bytes32 _metadataHash,
        bytes4 _batchId,
        uint256 index
    ) external;
}
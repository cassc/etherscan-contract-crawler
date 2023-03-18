// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { VRFV2WrapperConsumerBase } from './VRFV2WrapperConsumerBase.sol';
import { GovernedContract } from './GovernedContract.sol';
import { StorageBase } from './StorageBase.sol';
import { Ownable } from './Ownable.sol';

import { IMetadataGovernedProxy } from './interfaces/IMetadataGovernedProxy.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IMetadataStorage } from './interfaces/IMetadataStorage.sol';
import { IERC20 } from './interfaces/IERC20.sol';

contract MetadataStorage is StorageBase, IMetadataStorage {
    // Array of ids for uploaded batches of metadata hashes
    bytes4[] private batchIds;
    // Array of ids for randomness requests to Chainlink VRF service
    uint256[] private requestIds;
    // Mapping from batchIds to requestIds
    mapping(bytes4 => uint256) private requestIdsByBatchId;
    // Mapping from requestIds to batchIds
    mapping(uint256 => bytes4) private batchIdsByRequestId;
    // Mapping from batchIds to startingIndexes
    mapping(bytes4 => uint256) private startingIndexes;
    // Mapping from batchIds to metadataHashes
    mapping(bytes4 => bytes32[]) private metadataHashes;

    // Getter functions
    //
    function getRequestIdsCount() external view override returns (uint256 _count) {
        _count = requestIds.length;
    }

    function getRequestIdByIndex(uint256 _index)
        external
        view
        override
        returns (uint256 _requestId)
    {
        _requestId = requestIds[_index];
    }

    function getBatchIdsCount() external view override returns (uint256 _count) {
        _count = batchIds.length;
    }

    function getBatchIdByIndex(uint256 _index) external view override returns (bytes4 _batchId) {
        _batchId = batchIds[_index];
    }

    function getRequestIdByBatchId(bytes4 _batchId)
        external
        view
        override
        returns (uint256 _requestId)
    {
        _requestId = requestIdsByBatchId[_batchId];
    }

    function getBatchIdByRequestId(uint256 _requestId)
        external
        view
        override
        returns (bytes4 _batchId)
    {
        _batchId = batchIdsByRequestId[_requestId];
    }

    function getStartingIndex(bytes4 _batchId)
        external
        view
        override
        returns (uint256 _startingIndex)
    {
        _startingIndex = startingIndexes[_batchId];
    }

    function getMetadataHashesBatchLength(bytes4 _batchId)
        external
        view
        override
        returns (uint256 _length)
    {
        _length = metadataHashes[_batchId].length;
    }

    function getMetadataHashByIndex(bytes4 _batchId, uint256 _index)
        external
        view
        override
        returns (bytes32 _metadataHash)
    {
        _metadataHash = metadataHashes[_batchId][_index];
    }

    // Setter functions
    //
    function pushRequestId(uint256 _requestId) external override requireOwner {
        requestIds.push(_requestId);
    }

    function popRequestId() external override requireOwner {
        requestIds.pop();
    }

    function setRequestIdAtIndex(uint256 _requestId, uint256 index) external override requireOwner {
        requestIds[index] = _requestId;
    }

    function pushBatchId(bytes4 _batchId) external override requireOwner {
        batchIds.push(_batchId);
    }

    function popBatchId() external override requireOwner {
        batchIds.pop();
    }

    function setBatchIdAtIndex(bytes4 _batchId, uint256 index) external override requireOwner {
        batchIds[index] = _batchId;
    }

    function setRequestIdByBatchId(uint256 _requestId, bytes4 _batchId)
        external
        override
        requireOwner
    {
        requestIdsByBatchId[_batchId] = _requestId;
    }

    function setBatchIdByRequestId(bytes4 _batchId, uint256 _requestId)
        external
        override
        requireOwner
    {
        batchIdsByRequestId[_requestId] = _batchId;
    }

    function setStartingIndex(bytes4 _batchId, uint256 _startingIndex)
        external
        override
        requireOwner
    {
        startingIndexes[_batchId] = _startingIndex;
    }

    function setMetadataHashesBatch(bytes4 _batchId, bytes32[] calldata _metadataHashes)
        external
        override
        requireOwner
    {
        metadataHashes[_batchId] = _metadataHashes;
    }

    function pushMetadataHash(bytes4 _batchId, bytes32 _metadataHash)
        external
        override
        requireOwner
    {
        metadataHashes[_batchId].push(_metadataHash);
    }

    function popMetadataHash(bytes4 _batchId) external override requireOwner {
        metadataHashes[_batchId].pop();
    }

    function setMetadataHashAtIndex(
        bytes32 _metadataHash,
        bytes4 _batchId,
        uint256 index
    ) external override requireOwner {
        metadataHashes[_batchId][index] = _metadataHash;
    }
}

contract Metadata is VRFV2WrapperConsumerBase, GovernedContract, Ownable {
    // Data for migration
    //---------------------------------
    MetadataStorage public _storage;
    //---------------------------------

    uint32 public callbackGasLimit = 300000;
    uint16 public requestConfirmations = 12;
    uint32 public numWords = 1;

    constructor(
        address _proxy,
        address _link,
        address _vrfV2Wrapper
    ) VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper) GovernedContract(_proxy) {
        // Deploy Metadata storage
        _storage = new MetadataStorage();
        // Initialize proxy contract
        IMetadataGovernedProxy(_proxy).initialize(address(this));
    }

    // Governance functions
    //
    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IMetadataGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        // Transfer _storage ownership to new implementation
        _storage.setOwner(_newImpl);
        // Transfer LINK token balance to new implementation
        LINK.transfer(address(_newImpl), LINK.balanceOf(address(this)));
        _destroy(_newImpl);
    }

    // This function would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function getMetadataHash(uint256 tokenId) external view returns (bytes32 metadataHash) {
        require(tokenId > 0, 'Metadata: invalid tokenId');
        uint256 hashesCount = 0;
        bytes4 batchId;
        uint256 batchLength;
        for (uint256 i = 0; i < _storage.getBatchIdsCount(); i++) {
            batchId = _storage.getBatchIdByIndex(i);
            batchLength = _storage.getMetadataHashesBatchLength(batchId);
            if (hashesCount + batchLength >= tokenId) {
                break;
            } else {
                require(
                    i < _storage.getBatchIdsCount() - 1, // Revert if total hashes count is smaller than tokenId
                    'Metadata: no metadata hash for tokenId'
                );
                hashesCount += batchLength;
            }
        }
        uint256 startingIndex = _storage.getStartingIndex(batchId);
        require(
            startingIndex > 0,
            'Metadata: metadata hash has not been attributed yet for tokenId'
        );
        metadataHash = _storage.getMetadataHashByIndex(
            batchId,
            (startingIndex + tokenId - hashesCount) % batchLength
        );
    }

    // Owner-protected functions
    //
    function uploadMetadataHashes(bytes4 batchId, bytes32[] calldata metadataHashes)
        external
        onlyOwner
    {
        // Store batchId
        _storage.pushBatchId(batchId);
        // Store metadata hashes
        _storage.setMetadataHashesBatch(batchId, metadataHashes);
        // Emit MetadataHashesUploaded event
        IMetadataGovernedProxy(proxy).emitMetadataHashesUploaded(batchId, metadataHashes.length);
    }

    // This function is called once
    function requestRandomnessForStartingIndex(bytes4 batchId)
        public
        onlyOwner
        returns (uint256 requestId)
    {
        // Make sure no request has been made yet for batchId
        require(
            _storage.getRequestIdByBatchId(batchId) == 0,
            'Metadata: randomness already requested for metadata hashes batch'
        );
        // Make sure LINK balance is enough to pay for request
        require(
            VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit) <= LINK.balanceOf(address(this)),
            'Metadata: LINK balance is too low'
        );
        /**
         * See: https://docs.chain.link/vrf/v2/direct-funding/#explanation
         *
         * requestConfirmations: The number of block confirmations the VRF service will wait to respond.
         * callbackGasLimit: The maximum amount of gas to pay for completing the callback VRF function.
         * numWords: The number of random numbers to request.
         */
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        // Store requestId
        _storage.pushRequestId(requestId);
        // Store batchId and requestId
        _storage.setRequestIdByBatchId(requestId, batchId);
        _storage.setBatchIdByRequestId(batchId, requestId);
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setNumWords(uint32 _numWords) external onlyOwner {
        numWords = _numWords;
    }

    function transferERC20(
        address _erc20TokenAddress,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_erc20TokenAddress).transfer(_recipient, _amount);
    }

    // fulfillRandomWords callback implementation
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Get batchId
        bytes4 batchId = _storage.getBatchIdByRequestId(requestId);
        // Make sure starting index has not been set for batch
        require(
            _storage.getStartingIndex(batchId) == 0,
            'Metadata: starting index already set for metadata hashes batch'
        );
        uint256 batchLength = _storage.getMetadataHashesBatchLength(batchId);
        // Set starting index for batch
        uint256 startingIndex = randomWords[0] % batchLength;
        if (startingIndex == 0) {
            startingIndex = batchLength;
        }
        _storage.setStartingIndex(batchId, startingIndex);
        // Emit StartingIndexSet event
        IMetadataGovernedProxy(proxy).emitStartingIndexSet(batchId, startingIndex);
    }
}
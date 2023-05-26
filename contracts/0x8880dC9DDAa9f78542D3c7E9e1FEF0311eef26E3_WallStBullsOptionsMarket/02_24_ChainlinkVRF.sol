// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

abstract contract ChainlinkVRF is VRFConsumerBaseV2, ConfirmedOwner {
    uint32 private constant DEFAULT_CALLBACK_GAS_LIMIT = 500000;
    uint16 private constant DEFAULT_REQUEST_CONFIRMATIONS = 3;
    uint32 private constant DEFAULT_NUM_ROLLS = 1;

    struct ChainLinkConfig {
        uint64 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    ChainLinkConfig private chainLinkConfig;
    mapping(uint256 => uint256) public requests;
    VRFCoordinatorV2Interface private VRFCoordinator;

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    )
    VRFConsumerBaseV2(_vrfCoordinator)
    ConfirmedOwner(msg.sender) {
        VRFCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        chainLinkConfig = ChainLinkConfig({
            subscriptionId: _subscriptionId,
            keyHash: _keyHash,
            callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
            requestConfirmations: DEFAULT_REQUEST_CONFIRMATIONS,
            numWords: DEFAULT_NUM_ROLLS
        });
    }

    function getVRFConfiguration() external view returns (ChainLinkConfig memory) {
        return chainLinkConfig;
    }

    function updateVRFConfiguration(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) external onlyOwner {
        chainLinkConfig = ChainLinkConfig({
            subscriptionId: _subscriptionId,
            keyHash: _keyHash,
            callbackGasLimit: _callbackGasLimit,
            requestConfirmations: _requestConfirmations,
            numWords: _numWords
        });
    }

    function _requestRandomWords() internal returns (uint256 requestId) {
        return VRFCoordinator.requestRandomWords(
            chainLinkConfig.keyHash,
            chainLinkConfig.subscriptionId,
            chainLinkConfig.requestConfirmations,
            chainLinkConfig.callbackGasLimit,
            chainLinkConfig.numWords
        );
    }

    function getRequestStatus(uint256 _requestId) external view onlyOwner returns (uint256) {
        return _getRequestStatus(_requestId);
    }

    function _getRequestStatus(uint256 _requestId) internal view returns (uint256) {
        return requests[_requestId];
    }

    function _setRequestStatus(uint256 _requestId, uint256 _tokenId) internal {
        requests[_requestId] = _tokenId;
    }

    function ownerFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external onlyOwner {
        fulfillRandomWords(_requestId, _randomWords);
    }
}
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import "./interfaces/IRandomProvider.sol";
import "./interfaces/IBabylon7Core.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title RandomProvider
/// @notice RandomProvider is dedicated to interactions with the Chainlink VRF service and storage of
/// random requests data corresponding to listings from Babylon7Core
/// @dev RandomProvider inherits VRFConsumerBaseV2 contract and IRandomProvider interface.
contract RandomProvider is IRandomProvider, VRFConsumerBaseV2 {
    /// @dev Babylon7Core for accepting requests and pushing results
    IBabylon7Core public immutable core;
    /// @dev VRF coordinator for making requests
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    /// @dev VRF subscription identifier
    uint64 public immutable subscriptionId;
    /// @dev VRF gas price limiter key hash
    bytes32 public immutable keyHash;

    /// @dev requestId => requestStatus
    mapping(uint256 => RequestStatus) public requests;

    uint32 private constant CALLBACK_GAS_LIMIT = 500000;
    uint16 private constant REQUEST_CONFIRMATIONS = 20;
    uint16 private constant NUM_WORDS = 1;

    /// @dev Storage struct that contains info about random request
    struct RequestStatus {
        /// @dev Whether a requestId exists
        bool exists;
        /// @dev Timestamp of a request
        uint256 requestTimestamp;
        /// @dev To which listing a request corresponds
        uint256 listingId;
    }

    /// @notice Emitted when a random request is fulfilled by the Chainlink VRF
    /// @param requestId identifier of a random request
    /// @param listingId identifier of a listing
    /// @param randomWords array of acquired random words
    event RequestFulfilled(uint256 requestId, uint256 listingId, uint256[] randomWords);

    /// @notice Emitted when a random request is sent to the VRF coordinator
    /// @param requestId identifier of a random request
    /// @param listingId identifier of a listing
    event RequestSent(uint256 requestId, uint256 listingId);

    error OnlyBabylon7Core();
    error RequestIdNotFound();

    constructor(
        IBabylon7Core core_,
        address vrfCoordinator_,
        uint64 subscriptionId_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        core = core_;
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
    }

    /// @notice Accepts random words for a request and pushes the result to the Babylon7Core
    /// @dev inherited from VRFConsumerBaseV2
    /// @param _requestId identifier of a request
    /// @param _randomWords an array of random words
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (!requests[_requestId].exists) revert RequestIdNotFound();
        core.resolveWinner(requests[_requestId].listingId, _randomWords[0]);
        emit RequestFulfilled(_requestId, requests[_requestId].listingId, _randomWords);
    }

    /// @inheritdoc IRandomProvider
    function isRequestOverdue(uint256 requestId) external view override returns (bool) {
        return (block.timestamp > requests[requestId].requestTimestamp + 1 days);
    }

    /// @inheritdoc IRandomProvider
    function requestRandom(uint256 listingId) external override returns (uint256 requestId) {
        if (msg.sender != address(core)) revert OnlyBabylon7Core();

        requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        requests[requestId] = RequestStatus({exists: true, requestTimestamp: block.timestamp, listingId: listingId});
        emit RequestSent(requestId, listingId);
    }
}
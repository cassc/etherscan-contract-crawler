// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./interfaces/IRandomProvider.sol";
import "./interfaces/IBabylonCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract RandomProvider is IRandomProvider, Ownable, VRFConsumerBaseV2 {
    event RequestSent(uint256 requestId, uint256 listingId);
    event RequestFulfilled(uint256 requestId, uint256 listingId, uint256[] randomWords);

    struct RequestStatus {
        bool exists; // whether a requestId exists
        uint256 requestTimestamp; // timestamp of a request
        uint256 listingId; //to which listing request corresponds
    }

    mapping(uint256 => RequestStatus) public requests;  //requestId --> requestStatus

    VRFCoordinatorV2Interface immutable VRF_COORDINATOR;
    uint64 immutable subscriptionId;
    bytes32 immutable keyHash;

    IBabylonCore internal _core;

    uint32 constant CALLBACK_GAS_LIMIT = 500000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint16 constant NUM_WORDS = 1;

    constructor(
        address vrfCoordinator_,
        uint64 subscriptionId_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        VRF_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
    }

    function getBabylonCore() external view returns (address) {
        return address(_core);
    }

    function setBabylonCore(IBabylonCore core) external onlyOwner {
        _core = core;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory randomWords) internal override {
        require(requests[_requestId].exists, 'RandomProvider: requestId not found');
        _core.resolveClaimer(requests[_requestId].listingId, randomWords[0]);
        emit RequestFulfilled(_requestId, requests[_requestId].listingId, randomWords);
    }

    function isRequestOverdue(
        uint256 requestId
    ) external view override returns (bool) {
        if (block.timestamp > requests[requestId].requestTimestamp + 1 days) {
            return true;
        }

        return false;
    }

    function requestRandom(
        uint256 listingId
    ) external override returns (uint256 requestId) {
        require(msg.sender == address(_core), "RandomProvider: Only BabylonCore can request");
        requestId = VRF_COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        requests[requestId] = RequestStatus({exists: true, requestTimestamp: block.timestamp, listingId: listingId});
        emit RequestSent(requestId, listingId);
        return requestId;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract StakingPrizeRandomiser is VRFConsumerBaseV2 {
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomNumber;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256[] public requestIds;

    bytes32 keyHash;
    uint16 requestConfirmations = 3;

    constructor(
        uint64 _subscriptionId,
        address _coordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint32 _numWords)
        external
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            calculateCallbackGasLimit(_numWords),
            _numWords
        );
        s_requests[requestId] = RequestStatus({
            randomNumber: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomNumber = _randomWords;
    }

    function getDrawResults(uint256 _id, uint256 _drawSize)
        public
        view
        returns (uint256[] memory randomNumber)
    {
        uint256 requestId = requestIds[_id];
        RequestStatus memory request = s_requests[requestId];
        require(request.exists, "request not found");
        uint256[] memory drawResults = new uint256[](request.randomNumber.length);
        for (uint i = 0; i < request.randomNumber.length; i++) {
          drawResults[i] = (request.randomNumber[i] % _drawSize) + 1;
        }
        return drawResults;
    }


    // ==== GETTERS ====

    function getRequests(uint256 _request)
        public
        view
        returns (RequestStatus memory)
    {
        return s_requests[_request];
    }

    function calculateCallbackGasLimit(uint32 _numWords) pure internal returns (uint32) {
        return _numWords * 25000 + 10000;
    }
}
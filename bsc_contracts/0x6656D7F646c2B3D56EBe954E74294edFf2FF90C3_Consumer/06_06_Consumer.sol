// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract Consumer is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event AlreadyExists(bytes32 uniqueParam, uint256 existingRequestId);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    mapping(bytes32 => uint256)
        public uniqueParams; /* uniqueParam --> requestId */

    VRFCoordinatorV2Interface COORDINATOR;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 public keyHash;
    uint64 public s_subscriptionId;
    uint32 public callbackGasLimit = 2500000;
    uint16 minimumRequestConfirmations;

    constructor(
        uint64 subscriptionId,
        address coordinatorAddress,
        bytes32 _keyHash,
        uint16 _minimumRequestConfirmations
    ) VRFConsumerBaseV2(coordinatorAddress) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(coordinatorAddress);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        minimumRequestConfirmations = _minimumRequestConfirmations;
    }

    function requestRandomWords(
        uint32 _numWords,
        uint16 _requestConfirmations,
        bytes32 _uniqueParam
    ) external onlyOwner returns (uint256 requestId) {
        require(
            _requestConfirmations >= minimumRequestConfirmations,
            "Confirmation value too low"
        );

        uint256 existingRequestId = uniqueParams[_uniqueParam];

        if (_uniqueParam != 0x0 && existingRequestId != 0) {
            emit AlreadyExists(_uniqueParam, existingRequestId);

            return existingRequestId;
        } else {
            requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                _requestConfirmations,
                callbackGasLimit,
                _numWords
            );

            s_requests[requestId] = RequestStatus({
                randomWords: new uint256[](0),
                exists: true,
                fulfilled: false
            });

            uniqueParams[_uniqueParam] = requestId;
            requestIds.push(requestId);
            lastRequestId = requestId;

            emit RequestSent(requestId, _numWords);
            return requestId;
        }
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
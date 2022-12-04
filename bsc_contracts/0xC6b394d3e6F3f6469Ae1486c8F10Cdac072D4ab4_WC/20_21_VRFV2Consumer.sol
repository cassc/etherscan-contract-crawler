// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

abstract contract VRFV2Consumer is VRFConsumerBaseV2 {
    enum RequestStatus {
        Undefined,
        Pending,
        Fulfilled
    }

    struct Requests {
        address user;
        uint32 amount;
        RequestStatus status;
    }

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 public s_subscriptionId;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    bytes32 keyHash;

    mapping(uint => Requests) public idToRequests;
    mapping(address => uint[]) public userToRequests;

    constructor(
        uint64 subscriptionId,
        address _VRFConsumerBaseV2,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_VRFConsumerBaseV2) {
        COORDINATOR = VRFCoordinatorV2Interface(_VRFConsumerBaseV2);
        s_subscriptionId = subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        keyHash = _keyHash;
    }

    function _requestRandomWords(address user, uint32 amount) internal {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            amount
        );

        idToRequests[requestId] = Requests({
            user: user,
            amount: amount,
            status: RequestStatus.Pending
        });

        userToRequests[user].push(requestId);

        emit RandomRequest(requestId, user, amount);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {
        Requests storage request = idToRequests[requestId];

        request.status = RequestStatus.Fulfilled;

        emit RandomRequestFulfilled(requestId, request.user, randomWords);
    }

    function getUserByRequestId(
        uint256 requestId
    ) public view returns (address) {
        return idToRequests[requestId].user;
    }

    function getRequestById(
        uint256 requestId
    ) public view returns (address user, uint32 amount, RequestStatus status) {
        return (
            idToRequests[requestId].user,
            idToRequests[requestId].amount,
            idToRequests[requestId].status
        );
    }

    function getRequestIdsByUser(
        address user
    ) public view returns (uint256[] memory) {
        return userToRequests[user];
    }

    function getUserRequests(
        address user
    ) public view returns (Requests[] memory) {
        uint256[] memory requestsId = getRequestIdsByUser(user);
        Requests[] memory requests = new Requests[](requestsId.length);

        for (uint256 i = 0; i < requestsId.length; i++) {
            requests[i] = idToRequests[requestsId[i]];
        }

        return requests;
    }

    event RandomRequest(
        uint256 indexed requestId,
        address indexed user,
        uint256 amount
    );
    event RandomRequestFulfilled(
        uint256 indexed requestId,
        address indexed user,
        uint256[] randomWords
    );
}
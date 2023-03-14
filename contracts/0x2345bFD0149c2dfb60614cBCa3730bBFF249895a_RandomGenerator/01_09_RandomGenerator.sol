// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RandomGenerator is VRFConsumerBaseV2, AccessControl {
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Settings
    uint64 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(bytes32 => uint256) internal records;
    mapping(uint256 => RequestStatus) internal requests;

    event RequestSent(uint256 indexed requestId, uint32 indexed numWords);
    event RequestFulfilled(
        uint256 indexed requestId,
        uint256[] indexed randomWords
    );

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function requestRandomWords(
        string memory eventName,
        uint32 numWords
    ) external onlyRole(OPERATOR_ROLE) returns (uint256 requestId) {
        bytes32 name = keccak256(bytes(eventName));
        require(records[name] == 0, "record already existed");
        require(numWords > 0, "request at least one number");
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        records[name] = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(requests[requestId].exists, "request not found");
        requests[requestId].fulfilled = true;
        requests[requestId].randomWords = randomWords;
        emit RequestFulfilled(requestId, randomWords);
    }

    function getRequestStatus(
        uint256 requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(requests[requestId].exists, "request not found");
        RequestStatus memory request = requests[requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getRequestStatusByName(
        string memory eventName
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        bytes32 name = keccak256(bytes(eventName));
        require(records[name] != 0, "record not found");
        return getRequestStatus(records[name]);
    }

    function setOperationSettings(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    function setGeneralSettings(
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }
}
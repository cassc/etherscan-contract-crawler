// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

contract VRFv2Consumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 public immutable s_subscriptionId;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    /***
     * @dev vrf version - Main or Test - current Test
     *  Main Net
        address vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
        bytes32 keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
     *  Test Net
        address vrfCoordinator = 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
        bytes32 keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314; 
     */
    address vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    bytes32 keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;

    uint32 public callbackGasLimit = 5000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    address s_owner;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;

    // custom variables
    mapping(uint256 => uint256[]) public randomNumber;
    mapping(address => bool) public authorized;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        authorized[msg.sender] = true;
    }

    function setAuthorized(address authorizedAddress, bool isAuthorized) external onlyAuthorized {
        authorized[authorizedAddress] = isAuthorized;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyAuthorized returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({ randomWords: new uint256[](0), exists: true, fulfilled: false });
        requestIds.push(requestId);
        lastRequestId = requestId;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords);
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], 'User is not Authorized');
        _;
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function setGasLimit(uint32 limit) public onlyAuthorized {
        callbackGasLimit = limit;
    }
}
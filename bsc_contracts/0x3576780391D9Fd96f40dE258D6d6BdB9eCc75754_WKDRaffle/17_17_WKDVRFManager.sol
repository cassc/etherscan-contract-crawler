// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {VRFConsumerBase} from "./interfaces/IVRFConsumerBase.sol";
import {VRFCoordinatorInterface} from "./interfaces/IVRFCoordinator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Same_As_Before();
error Not_Authorized();
error Funding_Failed();
error Invalid_Request();

contract WKDVRFManager is VRFConsumerBase, Ownable {
    VRFCoordinatorInterface private immutable COORDINATOR;
    mapping(address => bool) public authorized;
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    uint256[] public requestIds;
    uint256 private _lastRequestId;
    uint64 private _subscriptionId;

    mapping(uint256 => RequestStatus) private requests;

    event AuthorizationUpdated(address previousController, bool status);
    event RequestSent(uint256 requestId, uint64 subId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event SubscriptionIdChanged(uint64 previous, uint64 current);

    bytes32 public immutable keyHash;

    constructor(
        address coordinator,
        bytes32 _keyHash,
        uint64 _subId
    ) VRFConsumerBase(coordinator) {
        COORDINATOR = VRFCoordinatorInterface(coordinator);
        _subscriptionId = _subId;
        keyHash = _keyHash;
    }

    receive() external payable {
        _fund(msg.value);
    }

    function updateAuthAccount(
        address account,
        bool status
    ) external onlyOwner {
        if (authorized[account] == status) revert Same_As_Before();
        authorized[account] = status;
        emit AuthorizationUpdated(account, status);
    }

    function requestRandomWords(
        uint64 subId,
        uint32 callbackGasLimit,
        uint32 numWords,
        uint16 confirmations
    ) external returns (uint256 requestId) {
        if (!authorized[_msgSender()]) revert Not_Authorized();
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            confirmations,
            callbackGasLimit,
            numWords
        );
        requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        _lastRequestId = requestId;
        emit RequestSent(requestId, subId, numWords);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (!requests[requestId].exists) revert Invalid_Request();
        requests[requestId].fulfilled = true;
        requests[requestId].randomWords = randomWords;
        emit RequestFulfilled(requestId, randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        if (!requests[_requestId].exists) revert Invalid_Request();
        RequestStatus memory request = requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function _fund(uint256 amount) internal {
        (bool ok, ) = address(COORDINATOR).call{value: amount}(
            abi.encodeWithSignature("deposit(uint64)", _subscriptionId)
        );
        if (!ok) revert Funding_Failed();
    }

    function updateSubId(uint64 newSubId) external onlyOwner {
        if (_subscriptionId == newSubId) revert Same_As_Before();
        emit SubscriptionIdChanged(_subscriptionId, newSubId);
        _subscriptionId = newSubId;
    }

    function subscriptionId() external view returns (uint64) {
        return _subscriptionId;
    }

    function lastRequestId() external view returns (uint256) {
        return _lastRequestId;
    }
}

// 0x0b43eFa3478b02ADA6783d523b0A89F5a2F81fCb - working condition
// 0xd11a9d04642bE7b1BA6E25A5311b1fE312Cf04c1 - improved conditon
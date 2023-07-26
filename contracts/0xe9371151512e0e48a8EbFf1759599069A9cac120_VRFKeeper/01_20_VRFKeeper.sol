// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "./IVRFKeeper.sol";
import "./IVRFSubcriber.sol";

import "hardhat/console.sol"; // TODO remove

contract VRFKeeper is IVRFKeeper, AccessControlEnumerable, VRFConsumerBaseV2, ConfirmedOwner {
	// ====================================================
	// ROLES
	// ====================================================
	bytes32 constant AUTHORIZED_SUBSCRIBER = keccak256("AUTHORIZED_SUBSCRIBER");

	// ====================================================
	// STATE
	// ====================================================
	VRFCoordinatorV2Interface VRF_COORDINATOR;
	uint64 subscriptionId;
	bytes32 gaslaneHash;
	uint32 callbackGasLimit = 1000000;
	uint16 minConfirmations = 3;

	uint256 public constant _FALSE = 1;
	uint256 public constant _TRUE = 2;
	uint256 public useFallback = _FALSE;
	uint256 public bypassRequestId = 0;

	mapping(uint256 => IVRFSubcriber) internal subscribers;

	// ====================================================
	// CONSTRUCTOR
	// ====================================================
	constructor(
		uint64 subscriptionId_,
		address vrfCoordinator_,
		bytes32 gaslaneHash_
	) VRFConsumerBaseV2(vrfCoordinator_) ConfirmedOwner(msg.sender) {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setRoleAdmin(AUTHORIZED_SUBSCRIBER, DEFAULT_ADMIN_ROLE);

		VRF_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
		gaslaneHash = gaslaneHash_;

		subscriptionId = subscriptionId_;
	}

	// ====================================================
	// ROLE GATED
	// ====================================================
	function setUseFallback(uint256 val) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require(val == _TRUE || val == _FALSE, "Invalid use fallback state");
		useFallback = val;
	}

	function setVrfCoordinator(address newCoordinator) public onlyRole(DEFAULT_ADMIN_ROLE) {
		VRF_COORDINATOR = VRFCoordinatorV2Interface(newCoordinator);
	}

	function setSubscriptionId(uint64 subscriptionId_) public onlyRole(DEFAULT_ADMIN_ROLE) {
		subscriptionId = subscriptionId_;
	}

	function setCallbackGasLimit(uint32 callbackGasLimit_) public onlyRole(DEFAULT_ADMIN_ROLE) {
		callbackGasLimit = callbackGasLimit_;
	}

	function setGasLaneHash(bytes32 gaslaneHash_) public onlyRole(DEFAULT_ADMIN_ROLE) {
		gaslaneHash = gaslaneHash_;
	}

	// /**
	//  * @notice this function is designed for EAO wallets bcz msg.sender
	//  * must be owner
	//  */
	// function removeConsumer() public onlyRole(DEFAULT_ADMIN_ROLE) {
	// 	VRF_COORDINATOR.removeConsumer(subscriptionId, address(this));
	// }

	function getSubscription()
		public
		view
		returns (uint96 balance_, uint64 reqCount_, address owner_, address[] memory consumers_)
	{
		(balance_, reqCount_, owner_, consumers_) = VRF_COORDINATOR.getSubscription(subscriptionId);
	}

	// ====================================================
	// PUBLIC
	// ====================================================
	function requestRandomness(
		uint32 numWords,
		IVRFSubcriber subscriberAddress
	) public onlyRole(AUTHORIZED_SUBSCRIBER) returns (uint256) {
		if (useFallback == _TRUE) {
			uint256[] memory words = new uint256[](numWords);
			for (uint256 i = 0; i < numWords; i += 1) {
				unchecked {
					/// @dev intentionally allowing overflow, testing needed
					words[i] = block.difficulty + uint256(blockhash(uint256(block.number) - i));

					// Todo: remove log
					console.log("requestRandomness fallback word (index, word)", i, words[i]);
				}
			}

			uint256 tmpReqId = bypassRequestId;
			bypassRequestId++;

			subscriberAddress._vrfCallback(tmpReqId, words);
			return tmpReqId;
		}

		uint256 requestId = VRF_COORDINATOR.requestRandomWords(
			gaslaneHash,
			subscriptionId,
			minConfirmations,
			callbackGasLimit,
			numWords
		);
		subscribers[requestId] = subscriberAddress;

		return requestId;
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		console.log("fulfillRandomWords (requestId, randomWords) ", requestId, randomWords[0]); // TODO remove

		IVRFSubcriber subscriberAddress = subscribers[requestId];

		if (address(subscriberAddress) != address(0)) {
			subscriberAddress._vrfCallback(requestId, randomWords);
		}
		delete subscribers[requestId];
	}
}
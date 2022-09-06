// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';

struct ChainlinkVRFConfig {
	address vrfCoordinator;
	bytes32 keyHash;
	uint64 subscriptionId;
	uint32 callbackGasLimit;
	uint16 requestConfirmations;
}

contract ChainlinkVRFConfigManager is Ownable {
	VRFCoordinatorV2Interface COORDINATOR;

	address public vrfCoordinator;

	// ID from subscription manager
	uint64 internal subscriptionId;

	// Keyhash depends on callbackGasLimit
	bytes32 internal keyHash;
	// Must be one of given gasLimits for network
	uint32 internal callbackGasLimit;
	uint16 internal requestConfirmations;

	event ChainlinkVRFConfigChanged(
		uint256 subscriptionId,
		bytes32 keyHash,
		uint32 callbackGasLimit,
		uint16 requestConfirmations
	);

	constructor(ChainlinkVRFConfig memory _chainlinkVRFConfig) {
		// ChainlinkVRF setup
		COORDINATOR = VRFCoordinatorV2Interface(_chainlinkVRFConfig.vrfCoordinator);

		vrfCoordinator = _chainlinkVRFConfig.vrfCoordinator;
		keyHash = _chainlinkVRFConfig.keyHash;
		callbackGasLimit = _chainlinkVRFConfig.callbackGasLimit;
		subscriptionId = _chainlinkVRFConfig.subscriptionId;
		requestConfirmations = _chainlinkVRFConfig.requestConfirmations;
	}

	function changeChainlinkVRFConfig(ChainlinkVRFConfig memory chainlinkVRFConfig) external onlyOwner {
		subscriptionId = chainlinkVRFConfig.subscriptionId;
		keyHash = chainlinkVRFConfig.keyHash;
		callbackGasLimit = chainlinkVRFConfig.callbackGasLimit;
		requestConfirmations = chainlinkVRFConfig.requestConfirmations;

		emit ChainlinkVRFConfigChanged(subscriptionId, keyHash, callbackGasLimit, requestConfirmations);
	}
}
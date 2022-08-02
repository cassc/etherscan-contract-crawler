// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';

// Chainlink and ChainlinkVRF config management contracts
import './ChainlinkConfigManagement/ChainlinkConfigManager.sol';
import './ChainlinkConfigManagement/ChainlinkVRFConfigManager.sol';

contract ChainlinkInfrastructureClient is
	ChainlinkClient,
	VRFConsumerBaseV2,
	ChainlinkConfigManager,
	ChainlinkVRFConfigManager
{
	constructor(ChainlinkConfig memory _chainlinkConfig, ChainlinkVRFConfig memory _chainlinkVRFConfig)
		ChainlinkConfigManager(_chainlinkConfig)
		ChainlinkVRFConfigManager(_chainlinkVRFConfig)
		VRFConsumerBaseV2(_chainlinkVRFConfig.vrfCoordinator)
	{
		setChainlinkToken(_chainlinkConfig.linkToken);
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {}
}
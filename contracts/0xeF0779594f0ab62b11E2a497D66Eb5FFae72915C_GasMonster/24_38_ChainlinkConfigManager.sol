// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import '@openzeppelin/contracts/access/Ownable.sol';

struct ChainlinkConfig {
	address linkToken;
	address oracle;
	bytes32 jobId;
	uint256 fee;
}

contract ChainlinkConfigManager is Ownable {
	address internal oracle;
	bytes32 internal jobId;
	uint256 internal fee;

	event ChainlinkConfigChanged(address oracle, bytes32 jobId, uint256 fee);

	constructor(ChainlinkConfig memory _chainlinkConfig) {
		// Chainlink setup
		oracle = _chainlinkConfig.oracle;
		jobId = _chainlinkConfig.jobId;
		fee = _chainlinkConfig.fee;
	}

	function changeChainlinkConfig(ChainlinkConfig memory chainlinkConfig) external onlyOwner {
		oracle = chainlinkConfig.oracle;
		jobId = chainlinkConfig.jobId;
		fee = chainlinkConfig.fee;

		emit ChainlinkConfigChanged(oracle, jobId, fee);
	}
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

contract MockChainlinkAggregator {
	int256 price;
	uint256 newUpdatedAt = 1681179848;

	constructor(int256 _price) {
		price = _price;
	}

	function latestAnswer() external view returns (int256) {
		return price;
	}

	function decimals() external pure returns (int256) {
		return 8;
	}

	function setPrice(int256 _price) external {
		price = _price;
	}

	function setUpdatedAt(uint256 _updatedAt) external {
		newUpdatedAt = _updatedAt;
	}

	function latestRoundData()
		public
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		roundId = 18446744073709552278;
		answer = price;
		startedAt = 1681179848;
		updatedAt = newUpdatedAt;
		answeredInRound = 18446744073709552278;
	}
}
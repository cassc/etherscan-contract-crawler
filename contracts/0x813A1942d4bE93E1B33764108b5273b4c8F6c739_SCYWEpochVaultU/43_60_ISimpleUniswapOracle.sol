// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISimpleUniswapOracle {
	event PriceUpdate(
		address indexed pair,
		uint256 priceCumulative,
		uint32 blockTimestamp,
		bool lastIsA
	);

	function MIN_T() external pure returns (uint32);

	function getBlockTimestamp() external view returns (uint32);

	function getPair(address uniswapV2Pair)
		external
		view
		returns (
			uint256 priceCumulativeA,
			uint256 priceCumulativeB,
			uint32 updateA,
			uint32 updateB,
			bool lastIsA,
			bool initialized
		);

	function initialize(address uniswapV2Pair) external;

	function getResult(address uniswapV2Pair) external returns (uint224 price, uint32 T);
}
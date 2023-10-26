// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IPriceProvider {
	function getTokenPrice() external view returns (uint256);

	function getTokenPriceUsd() external view returns (uint256);

	function getLpTokenPrice() external view returns (uint256);

	function getLpTokenPriceUsd() external view returns (uint256);

	function decimals() external view returns (uint256);

	function update() external;

	function baseAssetChainlinkAdapter() external view returns (address);
}
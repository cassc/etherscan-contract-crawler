// SPDX-License-Identifier: MIT
  
pragma solidity ^0.8.0;

interface IGhostFaucet {
	event AssetAirdropped(
		address indexed sender, 
		address indexed friend, 
		uint256 amount, 
		uint256 timestamp
	);

	/**
	 * @dev Minimal amount to be dispersed. Used only for addresses with
	 * multiple NFTs.
	 */
	function baseDisperse() external view returns (uint256);

	/**
	 * @dev Minimal reward amount.
	 */
	function baseAmount() external view returns (uint256);

	/**
	 * @dev Dynamic collection address.
	 */
	function nftAddress() external view returns (address);

	/**
	 * @dev ERC20 token address, which will be distributed as a collateral.
	 */
	function tokenAddress() external view returns (address);

	/**
	 * @dev Amount of tokens minted by faucet smart contract.
	 */
	function totalTokensMinted() external view returns (uint256);

	/**
	 * @dev Number of NFTs minted to address.
	 */
	function nftsMinted(address who) external view returns (uint256);

	/**
	 * @dev Amount of collateral tokens minted to address.
	 */
	function tokensMinted(address who) external view returns (uint256);

	/**
	 * @dev Number of invited referrals.
	 */
	function referralsNumber(address who) external view returns (uint256);

	/**
	 * @dev Used formula:
	 * y = a + (a * (x - B)) / sqrt((x - B)^2 + C)
	 */
	function sigmoidValue(uint256 x) external view returns (uint256);

	/**
	 * @dev Mints new NFT and collateralize NFT of a friend.
	 */
	function sendMeGhostNft(address friend) external payable;
}
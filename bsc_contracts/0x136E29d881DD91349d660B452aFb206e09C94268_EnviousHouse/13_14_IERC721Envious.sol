// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional Envious extension.
 * @author F4T50 @ghostchain
 * @author 571nkY @ghostchain
 * @author 5Tr3TcH @ghostchain
 * @dev Ability to collateralize each NFT in collection.
 */
interface IERC721Envious is IERC721 {
	event Collateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Uncollateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Dispersed(address indexed tokenAddress, uint256 amount);
	event Harvested(address indexed tokenAddress, uint256 amount, uint256 scaledAmount);

	/**
	 * @dev An array with two elements. Each of them represents percentage from collateral
	 * to be taken as a commission. First element represents collateralization commission.
	 * Second element represents uncollateralization commission. There should be 3 
	 * decimal buffer for each of them, e.g. 1000 = 1%.
	 *
	 * @param index of value in array.
	 */
	function commissions(uint256 index) external view returns (uint256);

	/**
	 * @dev Address of token that will be paid on bonds.
	 *
	 * @return address address of token.
	 */
	function ghostAddress() external view returns (address);

	/**
	 * @dev Address of smart contract, that provides purchasing of DeFi 2.0 bonds.
	 *
	 * @return address address of bonding smart.
	 */
	function ghostBondingAddress() external view returns (address);

	/**
	 * @dev 'Black hole' is any address that guarantee tokens sent to it will not be 
	 * retrieved from there. Note: some tokens revert on transfer to zero address.
	 *
	 * @return address address of black hole.
	 */
	function blackHole() external view returns (address);

	/**
	 * @dev Token that will be used to harvest collected commissions.
	 *
	 * @return address address of token.
	 */
	function communityToken() external view returns (address);

	/**
	 * @dev Pool of available tokens for harvesting.
	 *
	 * @param index in array.
	 * @return address of token.
	 */
	function communityPool(uint256 index) external view returns (address);

	/**
	 * @dev Token balance available for harvesting.
	 *
	 * @param tokenAddress addres of token.
	 * @return uint256 token balance.
	 */
	function communityBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Array of tokens that were dispersed.
	 *
	 * @param index in array.
	 * @return address address of dispersed token.
	 */
	function disperseTokens(uint256 index) external view returns (address);

	/**
	 * @dev Amount of tokens that was dispersed.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function disperseBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of tokens that was already taken from the disperse.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 total amount of tokens already taken.
	 */
	function disperseTotalTaken(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of disperse already taken by each tokenId.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 amount of tokens already taken.
	 */
	function disperseTaken(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Available payouts.
	 *
	 * @param bondId bond unique identifier.
	 * @return uint256 potential payout.
	 */
	function bondPayouts(uint256 bondId) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to array of bonds.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return uint256 index of bond.
	 */
	function bondIndexes(uint256 tokenId, uint256 index) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to token addresses who have collateralized before.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return address address of token.
	 */
	function collateralTokens(uint256 tokenId, uint256 index) external view returns (address);

	/**
	 * @dev Token balances that are stored under `tokenId`.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function collateralBalances(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Calculator function for harvesting.
	 *
	 * @param amount of `communityToken`s to spend
	 * @param tokenAddress of token to be harvested
	 * @return amount to harvest based on inputs
	 */
	function getAmount(uint256 amount, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Collect commission fees gathered in exchange for `communityToken`.
	 *
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function harvest(uint256[] memory amounts, address[] memory tokenAddresses) external;

	/**
	 * @dev Collateralize NFT with different tokens and amounts.
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function collateralize(
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;

	/**
	 * @dev Withdraw underlying collateral.
	 *
	 * Requirements:
	 * - only owner of NFT
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function uncollateralize(
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external;

	/**
	 * @dev Collateralize NFT with discount, based on available bonds. While
	 * purchased bond will have delay the owner will be current smart contract
	 *
	 * @param bondId the ID of the market
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param amount the amount of quote token to spend
	 * @param maxPrice the maximum price at which to buy bond
	 */
	function getDiscountedCollateral(
		uint256 bondId,
		address quoteToken,
		uint256 tokenId,
		uint256 amount,
		uint256 maxPrice
	) external;

	/**
	 * @dev Claim collateral inside this smart contract and extending underlying
	 * data mappings.
	 *
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param indexes array of note indexes to redeem
	 */
	function claimDiscountedCollateral(uint256 tokenId, uint256[] memory indexes) external;

	/**
	 * @dev Split collateral among all existent tokens.
	 *
	 * @param amounts to be dispersed among all NFT owners
	 * @param tokenAddresses of token to be dispersed
	 */
	function disperse(uint256[] memory amounts, address[] memory tokenAddresses) external payable;

	/**
	 * @dev See {IERC721-_mint}
	 */
	function mint(address who) external;
}
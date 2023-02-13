// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEnviousHouse {
	event Collateralized(
		address indexed collection,
		uint256 indexed tokenId,
		uint256 amount,
		address tokenAddress
	);
	
	event Uncollateralized(
		address indexed collection,
		uint256 indexed tokenId,
		uint256 amount,
		address tokenAddress
	);
	
	event Dispersed(
		address indexed collection,
		address indexed tokenAddress,
		uint256 amount
	);
	
	event Harvested(
		address indexed collection,
		address indexed tokenAddress,
		uint256 amount,
		uint256 scaledAmount
	);
	
	function totalCollections() external view returns (uint256);
	function ghostAddress(address collection) external view returns (address);
	function ghostBondingAddress(address collection) external view returns (address);
	function blackHole(address collection) external view returns (address);
	
	function collections(uint256 index) external view returns (address);
	function collectionIds(address collection) external view returns (uint256);
	function specificCollections(address collection) external view returns (bool);
	
	function commissions(address collection, uint256 index) external view returns (uint256);
	function communityToken(address collection) external view returns (address);
	function communityPool(address collection, uint256 index) external view returns (address);
	function communityBalance(address collection, address tokenAddress) external view returns (uint256);
	
	function disperseTokens(address collection, uint256 index) external view returns (address);
	function disperseBalance(address collection, address tokenAdddress) external view returns (uint256);
	function disperseTotalTaken(address collection, address tokenAddress) external view returns (uint256);
	function disperseTaken(address collection, uint256 tokenId, address tokenAddress) external view returns (uint256);
	
	function bondPayouts(address collection, uint256 bondId) external view returns (uint256);
	function bondIndexes(address collection, uint256 tokenId, uint256 index) external view returns (uint256);
	
	function collateralTokens(address collection, uint256 tokenId, uint256 index) external view returns (address);
	function collateralBalances(address collection, uint256 tokenId, address tokenAddress) external view returns (uint256);
	
	function getAmount(address collection, uint256 amount, address tokenAddress) external view returns (uint256);
	
	function setGhostAddresses(address ghostToken, address ghostBonding) external;
	function setSpecificCollection(address collection) external;
	
	function registerCollection(
		address collection,
		address token,
		uint256 incoming,
		uint256 outcoming
	) external payable;
	
	function harvest(
		address collection,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external;
	
	function collateralize(
		address collection,
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;
	
	function uncollateralize(
		address collection,
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external;
	
	function getDiscountedCollateral(
		address collection,
		uint256 bondId,
		address quoteToken,
		uint256 tokenId,
		uint256 amount,
		uint256 maxPrice
	) external;
	
	function claimDiscountedCollateral(
		address collection,
		uint256 tokenId,
		uint256[] memory indexes
	) external;
	
	function disperse(
		address collection,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;
}
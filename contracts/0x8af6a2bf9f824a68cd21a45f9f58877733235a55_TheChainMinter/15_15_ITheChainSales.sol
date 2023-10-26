//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITheChainSales {
	event NewOrder(uint256 orderId, address creator, uint256 tokenId, uint256 price, uint256 startsAt);

	event OrderClosed(uint256 orderId, address operator, bool canceled);

	struct Order {
		address creator;
		uint96 price;
		uint128 tokenId;
		uint128 startsAt;
	}

	function getOrders(uint256[] calldata orderIds) external view returns (Order[] memory);

	function fulfillOrder(uint256 orderId) external payable;

	function createOrder(address creator, uint96 price, uint128 tokenId, uint128 startsAt) external;
}
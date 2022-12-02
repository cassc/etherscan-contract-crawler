// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMarketDex {
	function createOrder(
		address _collectionAddress,
		address _paymentToken,
		address _itemOwner,
		uint256 _tokenId,
		uint256 _price
	) external returns (uint256 _orderId);

	function buy(uint256 _orderId, address _paymentToken) external returns (uint256, address, uint256, address);

	function editOrder(
		address _orderOwner,
		uint256 _orderId,
		uint256 _price
	) external returns (uint256, uint256);

	function cancelOrder(uint256 _orderId, address _orderOwner) external returns (address, address, uint256);
}
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAuctionDex {
	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		address _itemOwner,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external payable returns (uint256 _auctionId);

	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		address _bidOwner,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external returns (uint256 _bidAuctionId);

	function cancelAuction(uint256 _auctionId, address _auctionOwner, bool _isAcceptOffer) external returns (uint256);

	function cancelBidAuction(uint256 _bidAuctionId, address _auctionOwner) external returns (uint256, uint256, address);

	function reclaimAuction(uint256 _auctionId, address _auctionOwner) external returns (address, uint256);

	function acceptBidAuction(uint256 _bidAuctionId, address _auctionOwner) external returns (uint256, address, address, uint256, address, address);
}
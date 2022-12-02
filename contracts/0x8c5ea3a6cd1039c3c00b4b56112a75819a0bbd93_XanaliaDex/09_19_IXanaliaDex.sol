//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IXanaliaDex {
	/**
	 * User calls to create collection
	 */

	function createXanaliaCollection(
		string memory name_,
		string memory symbol_,
		bool _private
	) external;

	// function collectionCount() external view returns (uint256);

	// function collections(address _userAddress) external view returns (address[] calldata);

	// function collectionAddresses(uint256 _id) external view returns (address);

	// function xanaliaAddressesStorageAddress() external view returns (address);

	// function platformFee() external returns (uint256);

	// function paymentMethod(address _token) external returns (bool);

	// function isUserCollection(address _token) external returns (bool);

	// function isUserWhitelisted(address _token) external returns (bool);

	function setApproveForAllERC721(address _collectionAddress, address _spender) external;

	function mint(
		address _token,
		string calldata _tokenURI,
		uint256 _royaltyFee
	) external;

	function mintAndPutOnSale(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _price
	) external;

	function mintAndPutOnAuction(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external;

	function setPlatformFee(uint256 _platformFee) external;

	function setPaymentMethod(address _token, bool _status) external returns (bool);

	function createOrder(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _price
	) external;

	function buy(uint256 _orderId, address _paymentToken) external payable;

	function editOrder(
		uint256 _orderId,
		uint256 _price
	) external;

	function cancelOrder(uint256 _orderId) external;

	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external;

	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external;

	function editBidAuction(
		uint256 _bidAuctionId,
		uint256 _price,
		uint256 _expireTime
	) external;

	function cancelAuction(uint256 _auctionId) external;

	function cancelBidAuction(uint256 _bidAuctionId) external;

	function reclaimAuction(uint256 _auctionId) external;

	function acceptBidAuction(uint256 _bidAuctionId) external;

	function setWhitelistAddress(address[] calldata _user, bool[] calldata _status) external;

	function sendTokenToNewContract(address _token, address _newContract) external;
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketPlace {
	struct tokenMarketInfo {
		uint256 tokenId;
		uint256 totalSell;
		uint256 minPrice;
		uint256 artistRoyalty;
		uint256 artistfee;
		uint256 galleryownerfee;
		uint256 thirdpartyfee;
		uint256 feeExpiryTime;
		bool onSell;
		address payable galleryOwner;
		address payable artist;
		address payable thirdParty;
		bool USD;
		address owner;
	}

	struct feeInfo {
		uint256 totalartistfee;
		// uint256 totalgalleryownerfee;
		uint256 totalplatformfee;
		uint256 totalthirdpartyfee;
	}

	event Nftonsell(uint256 indexed _tokenid, uint256 indexed _price);
	event Nftbought(uint256 indexed _tokenid, address indexed _seller, address indexed _buyer, uint256 _price);
	event Cancelnftsell(uint256 indexed _tokenid);

	/*@notice buy the token listed for sell 
     @param _tokenId id of token  */
	function buy(uint256 _tokenId, address _buyer) external payable;

	function addAdmin(address _admin) external;

	function addGallery(address _gallery, bool _status) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param _minprice minimum price to sell token*/
	function sell(
		uint256 _tokenId,
		uint256 _minprice,
		uint256 _artistfee,
		uint256 _galleryownerfee,
		uint256 _thirdpartyfee,
		// uint256 _artistRoyalty,
		uint256 _expirytime,
		address thirdParty,
		address _gallery,
		address _artist,
		bool USD
	) external;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
	function cancelSell(uint256 _tokenId) external;

	///@notice resale the token
	///@param _tokenId id of the token to resale
	///@param _minPrice amount to be updated
	function resale(uint256 _tokenId, uint256 _minPrice) external;

	///@notice change the artist fee commission rate
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) external;

	///@notice change the gallery owner commssion rate
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) external;

	/* @notice  listtoken added on sale list */
	function listtokenforsale() external view returns (uint256[] memory);

	//@notice get token info
	//@params tokenId to get information about
	function gettokeninfo(uint256 _tokenId) external view returns (tokenMarketInfo memory);

	function changePlatformAddress(address _platform) external;
}
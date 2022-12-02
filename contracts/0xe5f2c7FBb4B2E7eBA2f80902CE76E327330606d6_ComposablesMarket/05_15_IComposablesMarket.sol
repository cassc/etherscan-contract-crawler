// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Composables Market

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface IComposablesMarket {
    struct Listing {
        address seller;
        address tokenAddress;
        uint256 tokenId;

        uint256 price;

		uint64 quantity;
		uint64 filled;
		uint64 maxPerAddress;		                

        bool completed; //8
        bool deleted; //8
    }
    	
    event ListingCreated(                                                         
        uint256 listingId,

        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,

        uint256 price,

		uint64 quantity,
		uint64 maxPerAddress		        
    );

    event ListingFilled(
        uint256 listingId,

        address indexed buyer, 
        address indexed tokenAddress,
        uint256 indexed tokenId,

        address seller, 
        uint256 price,
        uint64 quantity,
        uint256 sellerAmount,
        uint256 feeAmount
    );

    event ListingDeleted(uint256 indexed listingId, address indexed tokenAddress, uint256 indexed tokenId);

    event ListingFeeUpdated(uint256 listingFee);
    
    event Withdrawal(address indexed to, uint256 amount);
    
    function getTokenListings(address tokenAddress, uint256 tokenId) external view returns(uint256[] memory);

	function createListing(address tokenAddress, uint256 tokenId, uint256 price, uint64 quantity, uint64 maxPerAddress) external returns (uint256);

	function createListingBatch(address[] calldata tokenAddresses, uint256[] calldata tokenIds, uint256[] calldata prices, uint64[] calldata quantities, uint64[] calldata maxPerAddresses) external returns (uint256);
	
	function fillListing(uint256 listingId, uint64 quantity) external payable;

	function fillListingBatch(uint256[] calldata listingIds, uint64[] calldata quantities) external payable;
    		
    function deleteListing(uint256 listingId) external;    

	function deleteListingBatch(uint256[] calldata listingIds) external;
    
    function getListing(uint256 listingId) external view returns (Listing memory);

    function setListingFee(uint256 listingFee) external;
    
    function withdraw(address to, uint256 amount) external;

    function pause() external;

    function unpause() external;
}
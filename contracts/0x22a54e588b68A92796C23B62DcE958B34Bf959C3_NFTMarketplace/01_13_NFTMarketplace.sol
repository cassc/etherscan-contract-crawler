// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {

    ERC721Enumerable public nftContract;
    uint256 public listingPrice = 1e17;

    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price;
        bool active;
        address highestBidder;
        uint256 highestBid;
    }

    Listing[] public listings;

    mapping(uint256 => address) public nftOwners; // Track NFT ownership

    event NFTListed(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTDelisted(uint256 indexed listingId);
    event NFTSold(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 tokenId, uint256 price);
    event NewOffer(uint256 indexed listingId, address indexed buyer, uint256 amount);

    constructor(address _nftContract) {
        nftContract = ERC721Enumerable(_nftContract);
    }

    function listNFT(uint256 _tokenId, uint256 _price) external {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner");
        require(nftContract.getApproved(_tokenId) == address(this), "Contract not approved to transfer NFT");

        listings.push(Listing({
            seller: msg.sender,
            tokenId: _tokenId,
            price: _price,
            active: true,
            highestBidder: address(0),
            highestBid: 0
        }));

        // Set the initial owner of the NFT
        nftOwners[_tokenId] = msg.sender;

        emit NFTListed(listings.length - 1, msg.sender, _tokenId, _price);
    }

    function delistNFT(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "You are not the seller");

        listing.active = false;

        emit NFTDelisted(_listingId);
    }

    function makeOffer(uint256 _listingId) external payable {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing is not active");
        require(msg.value > listing.highestBid, "Offer too low");

        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).transfer(listing.highestBid);
        }

        listing.highestBidder = msg.sender;
        listing.highestBid = msg.value;

        emit NewOffer(_listingId, msg.sender, msg.value);
    }

    function acceptOffer(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing is not active");

        address highestBidder = listing.highestBidder;
        uint256 highestBid = listing.highestBid;

        require(highestBidder != address(0), "No offers to accept");

        // Verify that msg.sender is the current owner of the NFT
        require(nftOwners[listing.tokenId] == msg.sender, "You are not the owner of this NFT");

        // Transfer ownership of the NFT to the highest bidder
        nftContract.transferFrom(msg.sender, highestBidder, listing.tokenId);

        // Update listing data
        listing.seller = highestBidder; // New seller is the highest bidder
        listing.price = highestBid; // New price is the highest bid
        listing.highestBidder = address(0); // Reset highest bidder after successful sale
        listing.highestBid = 0; // Reset highest bid after successful sale

        // Update ownership mapping
        nftOwners[listing.tokenId] = highestBidder;

        // Send the payment to the seller
        payable(msg.sender).transfer(highestBid);

        emit NFTSold(_listingId, highestBidder, msg.sender, listing.tokenId, highestBid);
    }

    function updateNFTPrice(uint256 _listingId, uint256 _newPrice) external {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "You are not the seller");

        listing.price = _newPrice;
    }

    function setListingPrice(uint256 _newPrice) external onlyOwner {
        listingPrice = _newPrice;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
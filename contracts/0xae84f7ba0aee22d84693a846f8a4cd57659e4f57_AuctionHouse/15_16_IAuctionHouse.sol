// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Interface for Auction Houses
 */
interface IAuctionHouse {
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;                
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;        
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;
        // The address of recipient of the sale commission
    }

    struct Royalty {
        //The address of the beneficiary who will be receiving royalties for each sale
        address payable beneficiary;
        //The percentage of the sale the commission address receives
        //If percentage is set to 0, the full amount will be sent
        uint256 royaltyPercentage;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,        
        address auctionCurrency
    );
    
    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    event RoyaltySet(
        address indexed tokenContract,
        address indexed newBeneficiary,
        uint256 indexed royaltyPercentage
    );

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        uint256 bidTime,
        bool firstBid,
        bool extended
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,        
        address winner,        
        uint256 amount,                
        uint256 endTime,
        address auctionCurrency
    );

    event AuctionWithRoyaltiesEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,        
        address winner,
        uint256 amount,
        address beneficiaryAddress,
        uint256 royaltyAmount,  
        uint256 endTime,      
        address auctionCurrency
    );

    event AuctionCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,        
        address auctionCurrency
    ) external returns (uint256);

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external;

    function setRoyalty(
        address tokenContract, 
        address payable beneficiaryAddress, 
        uint256 royaltyPercentage
    ) external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;

    function setPublicAuctionsEnabled(bool status) external;

    function whitelistAccount(address sellerOrTokenContract) external;

    function removeWhitelistedAccount(address sellerOrTokenContract) external;

    function isWhitelisted(address sellerOrTekenContract) external view returns(bool);
        
    function addAuctioneer(address who) external;

    function removeAuctioneer(address who) external;

    function isAuctioneer(address who) external view returns(bool);


}
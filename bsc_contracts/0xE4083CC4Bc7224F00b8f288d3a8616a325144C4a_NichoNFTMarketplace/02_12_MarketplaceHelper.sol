/**
 * Submitted for verification at BscScan.com on 2022-09-28
 */

// File: contracts/MarketplaceHelper.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// Own interfaces
import "./interfaces/INFTBlackList.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

abstract contract MarketplaceHelper {
    /// NFT marketplace paused or not
    bool public isPaused;

    //-- Interfaces --//
    // Blacklist
    INFTBlackList public blacklistContract;

    // Listed item on marketplace (Fixed sale)
    struct Item {
        address creator;
        bool isListed;
        uint256 price;
    }

    // Auction Item
    struct AuctionItem {
        uint80 id;          // auction id
        address creator;
        uint256 highPrice;  // high price
        uint256 expireTs;
        bool isLive;
    }

    // Bid Item
    struct BidItem {
        uint80 auctionId;
        uint256 price;
    }

    constructor(
        address _blacklist
    ) {
        blacklistContract = INFTBlackList(_blacklist);

        isPaused = false;        
    }

    receive() external payable {}

    modifier notPaused {
        require(isPaused == false, "Paused");
        _;
    }

    // Middleware to check if NFT is in blacklist
    modifier notBlackList(address tokenAddress, uint256 tokenId) {
        require(
            blacklistContract.checkBlackList(tokenAddress, tokenId) == false,
            "This NFT is in blackList"
        );
        _;
    }
    
    // Middleware to check if msg.sender is token owner
    modifier onlyTokenOwner(address tokenAddress, uint256 tokenId) {
        address tokenOwner = IERC721(tokenAddress).ownerOf(tokenId);

        require(
            tokenOwner == msg.sender,
            "Token Owner: you are not a token owner"
        );
        _;
    }

    function setPause(bool _value) external  {
        isPaused = _value;
    }

    function checkApproval(address _tokenAddress, uint _tokenId)
        internal
        view
        returns (bool)
    {
        IERC721 tokenContract = IERC721(_tokenAddress);
        return
            tokenContract.getApproved(_tokenId) == address(this) ||
            tokenContract.isApprovedForAll(
                tokenContract.ownerOf(_tokenId),
                address(this)
            );
    }
}
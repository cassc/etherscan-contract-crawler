// SPDX-License-Identifier: GPL-3.0

/// @title Chain/Saw auction house

// LICENSE
// AuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/d87346f9286130af529869b8402733b1fabe885b/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// Modified with love by Chain/Saw <3.

pragma solidity ^0.8.7;

import { IERC721, IERC165 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IAuctionHouse } from "./interfaces/IAuctionHouse.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address to, uint256 value) external returns (bool);
}

/**
 * @title The Chain/Saw AuctionHouse
 */
contract AuctionHouse is IAuctionHouse, ReentrancyGuard, AccessControl, Ownable {  
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum percentage difference between the last bid amount and the current bid.
    uint8 public minBidIncrementPercentage;

    // The address of the WETH contract, so that any ETH transferred can be handled as an ERC-20
    address public wethAddress;

    // A mapping of all of the auctions currently running.
    mapping(uint256 => IAuctionHouse.Auction) public auctions;

    // A mapping of token contracts to royalty objects.
    mapping(address => IAuctionHouse.Royalty) public royaltyRegistry;

    // A mapping of all token contract addresses that ChainSaw allows on auction-house. These addresses
    // could belong to token contracts or individual sellers.
    mapping(address => bool) public whitelistedAccounts;

    // 721 interface id
    bytes4 constant interfaceId = 0x80ac58cd; 
    
    // Counter for incrementing auctionId
    Counters.Counter private _auctionIdTracker;

    // Tracks whether auction house is allowing non-owners to create auctions,
    // e.g. in the case of secondary sales.
    bool public publicAuctionsEnabled;
    
    // The role that has permissions to create and cancel auctions
    bytes32 public constant AUCTIONEER = keccak256("AUCTIONEER");

    /**
     * @notice Require that caller is authorized auctioneer
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Call must be made by administrator"
        );
        _;
    }

    /**
     * @notice Require that caller is authorized auctioneer
     */
    modifier onlyAuctioneer() {
        require(
            hasRole(AUCTIONEER, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Call must be made by authorized auctioneer"
        );
        _;
    }

    /**
     * @notice Require that the specified auction exists
     */
    modifier auctionExists(uint256 auctionId) {
        require(_exists(auctionId), "Auction doesn't exist");
        _;
    }

    /**
     * @notice constructor 
     */
    constructor(address _weth, address[] memory auctioneers) {
        wethAddress = _weth;
        timeBuffer = 15 * 60; // extend 15 minutes after every bid made in last 15 minutes
        minBidIncrementPercentage = 5; // 5%
        publicAuctionsEnabled = false;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint i = 0; i < auctioneers.length; i++) {
            _addAuctioneer(auctioneers[i]);
        } 
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the auctions mapping and emit an AuctionCreated event.     
     */
    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,                
        address auctionCurrency
    ) public override nonReentrant returns (uint256) {        
        require(
            IERC165(tokenContract).supportsInterface(interfaceId),
            "tokenContract does not support ERC721 interface"
        );  
        
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(
          tokenOwner == msg.sender,
          "Must be owner of NFT"
        );
        require(
            _isAuthorizedAction(tokenOwner, tokenContract),
            "Call must be made by authorized seller, token contract or auctioneer"
        );
    
        uint256 auctionId = _auctionIdTracker.current();

        auctions[auctionId] = Auction({
            tokenId: tokenId,
            tokenContract: tokenContract,            
            amount: 0,
            duration: duration,
            firstBidTime: 0,
            reservePrice: reservePrice,            
            tokenOwner: tokenOwner,
            bidder: payable(0),            
            auctionCurrency: auctionCurrency
        });

        IERC721(tokenContract).transferFrom(tokenOwner, address(this), tokenId);

        _auctionIdTracker.increment();

        emit AuctionCreated(auctionId, tokenId, tokenContract, duration, reservePrice, tokenOwner, auctionCurrency);
 
        return auctionId;
    }

    /**
     * @notice sets auction reserve price if auction has not already started     
     */
    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) 
        external 
        override 
        auctionExists(auctionId)            
    {       
        require(
          _isAuctioneer(msg.sender) || auctions[auctionId].tokenOwner == msg.sender,
          "Must be auctioneer or owner of NFT"
        );
        require(
            _isAuthorizedAction(
                auctions[auctionId].tokenOwner, 
                auctions[auctionId].tokenContract
            ),
            "Call must be made by authorized seller, token contract or auctioneer"
        );
        require(auctions[auctionId].firstBidTime == 0, "Auction has already started");        
        
        auctions[auctionId].reservePrice = reservePrice;

        emit AuctionReservePriceUpdated(auctionId, auctions[auctionId].tokenId, auctions[auctionId].tokenContract, reservePrice);
    }

    /**
     * @notice Set royalty information for a given token contract.
     * @dev Store the royal details in the royaltyRegistry mapping and emit an royaltySet event. 
     * Royalty can only be modified before any auction for tokenContract has started    
     */
    function setRoyalty(address tokenContract, address payable beneficiary, uint royaltyPercentage) 
        external 
        override 
        onlyAuctioneer                 
    {                
        royaltyRegistry[tokenContract] = Royalty({
            beneficiary: beneficiary,
            royaltyPercentage: royaltyPercentage
        });
        emit RoyaltySet(tokenContract, beneficiary, royaltyPercentage);
    }

    /**
     * @notice Create a bid on a token, with a given amount.
     * @dev If provided a valid bid, transfers the provided amount to this contract.
     * If the auction is run in native ETH, the ETH is wrapped so it can be identically to other
     * auction currencies in this contract.
     */
    function createBid(uint256 auctionId, uint256 amount)
        external
        override
        payable
        auctionExists(auctionId)
        nonReentrant
    {
        address payable lastBidder = auctions[auctionId].bidder;        
        require(
            auctions[auctionId].firstBidTime == 0 ||
            block.timestamp <
            auctions[auctionId].firstBidTime.add(auctions[auctionId].duration),
            "Auction expired"
        );
        require(
            amount >= auctions[auctionId].reservePrice,
                "Must send at least reservePrice"
        );
        require(
            amount >= auctions[auctionId].amount.add(
                auctions[auctionId].amount.mul(minBidIncrementPercentage).div(100)
            ),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        // If this is the first valid bid, we should set the starting time now.
        // If it's not, then we should refund the last bidder
        if(auctions[auctionId].firstBidTime == 0) {
            auctions[auctionId].firstBidTime = block.timestamp;
        } else if(lastBidder != address(0)) {
            _handleOutgoingBid(lastBidder, auctions[auctionId].amount, auctions[auctionId].auctionCurrency);
        }

        _handleIncomingBid(amount, auctions[auctionId].auctionCurrency);

        auctions[auctionId].amount = amount;
        auctions[auctionId].bidder = payable(msg.sender);


        bool extended = false;
        // at this point we know that the timestamp is less than start + duration (since the auction would be over, otherwise)
        // we want to know by how much the timestamp is less than start + duration
        // if the difference is less than the timeBuffer, increase the duration by the timeBuffer
        if (
            auctions[auctionId].firstBidTime.add(auctions[auctionId].duration).sub(
                block.timestamp
            ) < timeBuffer
        ) {
            // Playing code golf for gas optimization:
            // uint256 expectedEnd = auctions[auctionId].firstBidTime.add(auctions[auctionId].duration);
            // uint256 timeRemaining = expectedEnd.sub(block.timestamp);
            // uint256 timeToAdd = timeBuffer.sub(timeRemaining);
            // uint256 newDuration = auctions[auctionId].duration.add(timeToAdd);
            uint256 oldDuration = auctions[auctionId].duration;
            auctions[auctionId].duration =
                oldDuration.add(timeBuffer.sub(auctions[auctionId].firstBidTime.add(oldDuration).sub(block.timestamp)));
            extended = true;
        }

        emit AuctionBid(
            auctionId,
            auctions[auctionId].tokenId,
            auctions[auctionId].tokenContract,
            msg.sender,
            amount,
            block.timestamp,
            lastBidder == address(0), // firstBid boolean
            extended
        );

        if (extended) {
            emit AuctionDurationExtended(
                auctionId,
                auctions[auctionId].tokenId,
                auctions[auctionId].tokenContract,
                auctions[auctionId].duration
            );
        }
    }

    /**
     * @notice End an auction and pay out the respective parties.
     * @dev If for some reason the auction cannot be finalized (invalid token recipient, for example),
     * The auction is reset and the NFT is transferred back to the auction creator.
     */
    function endAuction(uint256 auctionId) external override auctionExists(auctionId) nonReentrant {
        require(
            uint256(auctions[auctionId].firstBidTime) != 0,
            "Auction hasn't begun"
        );
        require(
            block.timestamp >=
            auctions[auctionId].firstBidTime.add(auctions[auctionId].duration),
            "Auction hasn't completed"
        );

        address currency = auctions[auctionId].auctionCurrency == address(0) ? wethAddress : auctions[auctionId].auctionCurrency;

        uint256 tokenOwnerProfit = auctions[auctionId].amount;
        address tokenContract = auctions[auctionId].tokenContract;
 
        // Otherwise, transfer the token to the winner and pay out the participants below
        try IERC721(auctions[auctionId].tokenContract).safeTransferFrom(address(this), auctions[auctionId].bidder, auctions[auctionId].tokenId) {} catch {
            _handleOutgoingBid(auctions[auctionId].bidder, auctions[auctionId].amount, auctions[auctionId].auctionCurrency);
            _cancelAuction(auctionId);
            return;
        }

        if (
            royaltyRegistry[tokenContract].beneficiary != address(0) && 
            royaltyRegistry[tokenContract].beneficiary != auctions[auctionId].tokenOwner &&
            royaltyRegistry[tokenContract].royaltyPercentage > 0
        ){
            uint256 royaltyAmount = _generateRoyaltyAmount(auctionId, auctions[auctionId].tokenContract);
            uint256 amountRemaining = tokenOwnerProfit.sub(royaltyAmount);
            

            _handleOutgoingBid(royaltyRegistry[tokenContract].beneficiary, royaltyAmount, auctions[auctionId].auctionCurrency);
            _handleOutgoingBid(auctions[auctionId].tokenOwner, amountRemaining, auctions[auctionId].auctionCurrency);


            emit AuctionWithRoyaltiesEnded(
                auctionId,
                auctions[auctionId].tokenId,
                auctions[auctionId].tokenContract,
                auctions[auctionId].tokenOwner,            
                auctions[auctionId].bidder,
                amountRemaining,
                royaltyRegistry[tokenContract].beneficiary,
                royaltyAmount,            
                block.timestamp,
                currency
            );


        } else {
            _handleOutgoingBid(auctions[auctionId].tokenOwner, tokenOwnerProfit, auctions[auctionId].auctionCurrency);

            emit AuctionEnded(
                auctionId,
                auctions[auctionId].tokenId,
                auctions[auctionId].tokenContract,
                auctions[auctionId].tokenOwner,            
                auctions[auctionId].bidder,                
                tokenOwnerProfit,  
                block.timestamp,                                          
                currency
            );
        }
        
        delete auctions[auctionId];
    }
    
    /**
     * @notice Cancel an auction.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCanceled event
     */
    function cancelAuction(uint256 auctionId) 
        external 
        override 
        nonReentrant 
        auctionExists(auctionId)        
    {        
        require(
          _isAuctioneer(msg.sender) || auctions[auctionId].tokenOwner == msg.sender,
          "Must be auctioneer or owner of NFT"
        );
        require(
            _isAuthorizedAction(
                auctions[auctionId].tokenOwner, 
                auctions[auctionId].tokenContract
            ),
            "Call must be made by authorized seller, token contract or auctioneer"
        );
        require(
            uint256(auctions[auctionId].firstBidTime) == 0,
            "Can't cancel an auction once it's begun"
        );
        _cancelAuction(auctionId);
    }

    /**
     * @notice enable or disable auctions to be created on the basis of whitelist
     */
    function setPublicAuctionsEnabled(bool status) external override onlyAdmin {
        publicAuctionsEnabled = status;
    }

    /**
      * @notice add account representing token owner (seller) or token contract to the whitelist
     */
    function whitelistAccount(address sellerOrTokenContract) external override onlyAuctioneer {
        _whitelistAccount(sellerOrTokenContract);
    }

    function removeWhitelistedAccount(address sellerOrTokenContract) external override onlyAuctioneer {
        delete whitelistedAccounts[sellerOrTokenContract];
    }

    function isWhitelisted(address sellerOrTekenContract) external view override returns(bool){
        return _isWhitelisted(sellerOrTekenContract);
    }
    
    function addAuctioneer(address who) external override onlyAdmin {
        _addAuctioneer(who);
    }

    function removeAuctioneer(address who) external override onlyAdmin {
        revokeRole(AUCTIONEER, who);
    }

    function isAuctioneer(address who) external view override returns(bool) {
        return _isAuctioneer(who);
    }
    
    function _isAuctioneer(address who) internal view returns(bool) {
        return hasRole(AUCTIONEER, who) || hasRole(DEFAULT_ADMIN_ROLE, who);
    }

    /**
     * @dev Given an amount and a currency, transfer the currency to this contract.
     * If the currency is ETH (0x0), attempt to wrap the amount as WETH
     */
    function _handleIncomingBid(uint256 amount, address currency) internal {
        // If this is an ETH bid, ensure they sent enough and convert it to WETH under the hood
        if(currency == address(0)) {
            require(msg.value == amount, "Sent ETH Value does not match specified bid amount");
            IWETH(wethAddress).deposit{value: amount}();
        } else {
            // We must check the balance that was actually transferred to the auction,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            IERC20 token = IERC20(currency);
            uint256 beforeBalance = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(beforeBalance.add(amount) == afterBalance, "Token transfer call did not transfer expected amount");
        }
    }

    function _handleOutgoingBid(address to, uint256 amount, address currency) internal {
        // If the auction is in ETH, unwrap it from its underlying WETH and try to send it to the recipient.
        if(currency == address(0)) {
            IWETH(wethAddress).withdraw(amount);

            // If the ETH transfer fails (sigh), rewrap the ETH and try send it as WETH.
            if(!_safeTransferETH(to, amount)) {
                IWETH(wethAddress).deposit{value: amount}();
                IERC20(wethAddress).safeTransfer(to, amount);
            }
        } else {
            IERC20(currency).safeTransfer(to, amount);
        }
    }

    function _generateRoyaltyAmount(uint256 auctionId, address tokenContract) internal view returns (uint256) {
        return auctions[auctionId].amount.div(100).mul(royaltyRegistry[tokenContract].royaltyPercentage);
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    function _cancelAuction(uint256 auctionId) internal {
        address tokenOwner = auctions[auctionId].tokenOwner;
        IERC721(auctions[auctionId].tokenContract).safeTransferFrom(address(this), tokenOwner, auctions[auctionId].tokenId);

        emit AuctionCanceled(auctionId, auctions[auctionId].tokenId, auctions[auctionId].tokenContract, tokenOwner);
        delete auctions[auctionId];
    }

    function _exists(uint256 auctionId) internal view returns(bool) {
        return auctions[auctionId].tokenOwner != address(0);
    }

    /**
     * @dev returns true if 
     */
    function _isAuthorizedAction(address seller, address tokenContract) internal view returns(bool) {
        if (hasRole(DEFAULT_ADMIN_ROLE, seller) || hasRole(AUCTIONEER, seller)) {
            return true;
        }

        if (publicAuctionsEnabled) {
            return _isWhitelisted(seller) || _isWhitelisted(tokenContract);
        }

        return false;
    }

    function _addAuctioneer(address who) internal {        
        _setupRole(AUCTIONEER, who);
    }

    function _isWhitelisted(address sellerOrTokenContract) internal view returns(bool) {
        return whitelistedAccounts[sellerOrTokenContract];
    }

    function _whitelistAccount(address sellerOrTokenContract) internal {        
        whitelistedAccounts[sellerOrTokenContract] = true;
    }
    
    receive() external payable {}
    fallback() external payable {}
}
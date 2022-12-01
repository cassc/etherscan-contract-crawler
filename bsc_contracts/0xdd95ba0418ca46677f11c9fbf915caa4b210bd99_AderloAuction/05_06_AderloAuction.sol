// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Auth.sol";

interface ISTDNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function creatorOf(uint256 _tokenId) external view returns (address);
    function royalty() external view returns (uint256);
    function royalties(uint256 _tokenId) external view returns (uint256);
    function collectionOwner() external view returns (address);
}

interface IAderloNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

contract AderloAuction is Auth, ERC721Holder {
    using SafeMath for uint256;
    using Address for address;

    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public MIN_BID_INCREMENT_PERCENT = 50; // 5%
    uint256 public swapFee = 25;  // 2.5% for admin tx fee
    address public swapFeeAddress;
    
    // Bid struct to hold bidder and amount
    struct Bid {
        address from;
        uint256 bidPrice;
    }

    // Auction struct which holds all the required info
    struct Auction {
        uint256 auction_id;
        address collection;
        uint256 token_id;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        address creator;
        address owner;
        bool active;
    }
    uint256 public currentID;
    // Array with all auctions
    mapping(uint256 => Auction) public auctions;
    // Mapping from auction index to user bids
    mapping (uint256 => Bid[]) public auctionBids;

    uint256 public referral_fee = 50;  // unit=1000, (5% = 50)
    struct Referral {
        bool referred;
        address referred_by;
    }
    mapping(address => Referral) public referrals;

    event BidSuccess(address _from, uint256 _auctionId, uint256 _amount, uint256 _bidIndex);
    // AuctionCreated is fired when an auction is created
    event AuctionCreated(Auction auction);
    // AuctionCanceled is fired when an auction is canceled
    event AuctionCanceled(uint _auctionId);
    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(Bid bid, Auction auction);

    constructor () Auth(msg.sender) { swapFeeAddress = msg.sender; }

    function setFee(uint256 _swapFee, address _swapFeeAddress) external authorized {
        swapFee = _swapFee;
        swapFeeAddress = _swapFeeAddress;
    }

    function createAuction(
        address _collection, 
        uint256 _token_id, 
        uint256 _startPrice, 
        uint256 _startTime, 
        uint256 _endTime
    ) OnlyItemOwner(_collection, _token_id) public {
        require(block.timestamp < _endTime, "end timestamp have to be bigger than current time");
        ISTDNFT nft = ISTDNFT(_collection);
        nft.safeTransferFrom(msg.sender, address(this), _token_id);

        currentID = currentID.add(1);
        Auction memory newAuction;
        newAuction.auction_id = currentID;
        newAuction.collection = _collection;
        newAuction.token_id = _token_id;
        newAuction.startPrice = _startPrice;
        newAuction.startTime = _startTime;
        newAuction.endTime = _endTime;
        newAuction.owner = msg.sender;
        newAuction.creator = getNFTCreator(_collection, _token_id);
        newAuction.active = true;
        auctions[currentID] = newAuction;
        emit AuctionCreated(newAuction);
    }
    
    function finalizeAuction(uint256 auctionId) public {
        Auction storage myAuction = auctions[auctionId];
        require(auctionId <= currentID && myAuction.active, "Invalid Auction Id");
        uint256 bidsLength = auctionBids[auctionId].length;
        require(msg.sender == myAuction.owner, "Only auction owner can finalize");
        uint256 _tokenId = myAuction.token_id;
        // if there are no bids cancel
        if (bidsLength == 0) {
            ISTDNFT(myAuction.collection).safeTransferFrom(address(this), myAuction.owner, _tokenId);
            myAuction.active = false;
            myAuction = myAuction;
            emit AuctionCanceled(auctionId);
        } else {
            // the money goes to the auction owner
            Bid memory lastBid = auctionBids[auctionId][bidsLength - 1];
            
            uint256 nftRoyalty = getRoyalty(myAuction.collection);
            address collection_owner = getCollectionOwner(myAuction.collection);
            uint256 nftRoyalties = getRoyalties(myAuction.collection, _tokenId);
            address itemCreator = getNFTCreator(myAuction.collection, _tokenId);

            uint256 feeAmount = lastBid.bidPrice.mul(swapFee).div(PERCENTS_DIVIDER);
            uint256 royaltyAmount = lastBid.bidPrice.mul(nftRoyalty).div(PERCENTS_DIVIDER);
            uint256 royaltiesAmount = lastBid.bidPrice.mul(nftRoyalties).div(PERCENTS_DIVIDER);
            uint256 sellerAmount = lastBid.bidPrice.sub(feeAmount).sub(royaltyAmount).sub(royaltiesAmount);
            
            if (referrals[msg.sender].referred) {
                uint256 referralAmount = lastBid.bidPrice.mul(referral_fee).div(PERCENTS_DIVIDER);
                (bool rs, ) = payable(referrals[msg.sender].referred_by).call{value: referralAmount}("");
                require(rs, "Failed to send referral fee to referral user");
                sellerAmount = sellerAmount.sub(referralAmount);
            }
            if(swapFee > 0) {
                (bool fs, ) = payable(swapFeeAddress).call{value: feeAmount}("");
                require(fs, "Failed to send fee to fee address");
            }
            if(nftRoyalty > 0 && collection_owner != address(0x0)) {
                (bool hs, ) = payable(collection_owner).call{value: royaltyAmount}("");
                require(hs, "Failed to send collection royalties to collection owner");
            }
            if(nftRoyalties > 0 && itemCreator != address(0x0)) {
                (bool ps, ) = payable(itemCreator).call{value: royaltiesAmount}("");
                require(ps, "Failed to send item royalties to item creator");
            }
            (bool os, ) = payable(myAuction.owner).call{value: sellerAmount}("");
            require(os, "Failed to send to item owner");
            ISTDNFT(myAuction.collection).safeTransferFrom(address(this), lastBid.from, _tokenId);
            myAuction.active = false;
            emit AuctionFinalized(lastBid, myAuction);
        }
    }
    
    function bidOnAuction(uint256 _auction_id, uint256 amount, address _ref_address) external payable {
        require(_auction_id <= currentID && auctions[_auction_id].active, "Invalid Auction Id");
        Auction memory myAuction = auctions[_auction_id];
        require(myAuction.owner != msg.sender, "Owner can not bid");
        require(block.timestamp < myAuction.endTime, "auction is over");
        require(block.timestamp >= myAuction.startTime, "auction is not started");

        uint256 bidsLength = auctionBids[_auction_id].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;
        if( bidsLength > 0 ) {
            lastBid = auctionBids[_auction_id][bidsLength - 1];
            tempAmount = lastBid.bidPrice.mul(PERCENTS_DIVIDER + MIN_BID_INCREMENT_PERCENT).div(PERCENTS_DIVIDER);
        }
        require(msg.value >= tempAmount, "too small amount");
        require(msg.value >= amount, "too small balance");
        if( bidsLength > 0 ) {
            (bool result, ) = payable(lastBid.from).call{value: lastBid.bidPrice}("");
            require(result, "Failed to send to the last bidder!");
        }
        if (referrals[msg.sender].referred == false && _ref_address != msg.sender && _ref_address != address(0)) {
            referrals[msg.sender].referred_by = _ref_address;
            referrals[msg.sender].referred = true;
        }

        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.bidPrice = amount;
        auctionBids[_auction_id].push(newBid);
        emit BidSuccess(msg.sender, _auction_id, newBid.bidPrice, bidsLength);
    }
    
    function getBidsAmount(uint256 _auction_id) public view returns(uint) {
        return auctionBids[_auction_id].length;
    }
    
    function getCurrentBids(uint256 _auction_id) public view returns(uint256, address) {
        uint256 bidsLength = auctionBids[_auction_id].length;
        // if there are bids refund the last bid
        if (bidsLength >= 0) {
            Bid memory lastBid = auctionBids[_auction_id][bidsLength - 1];
            return (lastBid.bidPrice, lastBid.from);
        }    
        return (0, address(0));
    }

    function getRoyalty(address collection) view internal returns(uint256) {
        ISTDNFT nft = ISTDNFT(collection);
        try nft.royalty() returns (uint256 value) {
            return value;
        } catch {
            IAderloNFT aderloNFT = IAderloNFT(collection);
            try aderloNFT.royaltyInfo(1, 1000) returns (address, uint256 _salePrice) {
                return _salePrice;
            } catch {
                return 0;
            }
        }
    }

    function getRoyalties(address collection, uint256 tokenId) view internal returns(uint256) {
        ISTDNFT nft = ISTDNFT(collection);
        try nft.royalties(tokenId) returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }

    function getNFTCreator(address collection, uint256 tokenId) view internal returns(address) {
        ISTDNFT nft = ISTDNFT(collection); 
        try nft.creatorOf(tokenId) returns (address creatorAddress) {
            return creatorAddress;
        } catch {
            return address(0x0);
        }
    }

    function getCollectionOwner(address collection) view internal returns(address) {
        ISTDNFT nft = ISTDNFT(collection); 
        try nft.collectionOwner() returns (address collection_owner) {
            return collection_owner;
        } catch {
            IAderloNFT aderloNFT = IAderloNFT(collection);
            try aderloNFT.royaltyInfo(1, 1000) returns (address _receiver, uint256) {
                return _receiver;
            } catch {
                return address(0x0);
            }
        }
    }
    
    modifier OnlyItemOwner(address _collection, uint256 _tokenId) {
        ISTDNFT collectionContract = ISTDNFT(_collection);
        require(collectionContract.ownerOf(_tokenId) == msg.sender);
        _;
    }

    function setReferralFee(uint256 _ref_fee) external authorized {
        require(_ref_fee < 100, "Fee should not greater than product cost!");
        referral_fee = _ref_fee;
    }
}
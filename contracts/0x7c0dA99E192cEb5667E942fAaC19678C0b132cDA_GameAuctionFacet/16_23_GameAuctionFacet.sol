//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/SafeTransferLib.sol";

import "@solidstate/contracts/utils/ReentrancyGuard.sol";
import "./LibStorage.sol";

import {ERC1155DInternal} from "./ERC1155D/ERC1155DInternal.sol";
import {GameInternalFacet} from "./GameInternalFacet.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

contract GameAuctionFacet is ERC1155DInternal, WithStorage, ReentrancyGuard,
GameInternalFacet, UsingDiamondOwner {
    using SafeTransferLib for address;
    
    event AuctionStarted(uint indexed auctionId, uint startTime, uint endTime);
    event AuctionExtended(uint indexed auctionId, uint endTime);
    event AuctionBid(uint indexed auctionId, address indexed bidder, uint bidValue, bool auctionExtended);
    event AuctionSettled(uint indexed auctionId, address indexed winner, uint amount);
    
    function updateAuctionConfig(GameAuctionConfigStorage calldata newConfig) external onlyRole(ADMIN) {
        acs().auctionEnabled = newConfig.auctionEnabled;
        acs().auctionDuration = newConfig.auctionDuration;
        acs().timeBuffer = newConfig.timeBuffer;
        acs().reservePrice = newConfig.reservePrice;
        acs().minBidAmountIfCurrentBidZero = newConfig.minBidAmountIfCurrentBidZero;
        acs().minBidIncrementPercentage = newConfig.minBidIncrementPercentage;
    }
    
    function settleCurrentAndCreateNewAuction() external nonReentrant {
        if (auct().startTime == 0 || auct().settled) {
            _createAuction();
            return;
        }
        
        _settleAuction();
        _createAuction();
    }

    function settleAuction() external nonReentrant {
        _settleAuction();
    }
    
    function auctionMinNextBid() public view returns (uint minAmountToBid) {
        uint minBidAmountIfCurrentBidPositive = auct().highestBidAmount + ((auct().highestBidAmount * acs().minBidIncrementPercentage) / 100);

        if (auct().highestBidder != address(0)) {
            minAmountToBid = auct().highestBidAmount == 0 ?
                                acs().minBidAmountIfCurrentBidZero :
                                minBidAmountIfCurrentBidPositive;
        } else {
            minAmountToBid = acs().reservePrice;
        }
    }

    function createBid() external payable nonReentrant {
        require(!auctionEnded(), 'Auction expired');
        require(auctionStarted() && !auct().settled, 'Auction not in progress');
        require(msg.value >= auctionMinNextBid(), "Insufficient bid amount");
        
        if (auct().highestBidder != address(0)) {
            auct().highestBidder.forceSafeTransferETH(auct().highestBidAmount);
        }
        
        auct().highestBidAmount = msg.value;
        auct().highestBidder = msg.sender;
        
        bool extendAuction = auct().endTime - block.timestamp < acs().timeBuffer;
        if (extendAuction) {
            auct().endTime = uint64(block.timestamp) + acs().timeBuffer;
            emit AuctionExtended(auct().auctionId, auct().endTime);
        }

        emit AuctionBid(auct().auctionId, auct().highestBidder, auct().highestBidAmount, extendAuction);
    }
    
    function _createAuction() internal {
        require(acs().auctionEnabled, "Creating new auctions is disabled");
        require(auct().startTime == 0 || auct().settled, 'Auction already in progress');

        auct().auctionId = auct().auctionId + 1;
        auct().highestBidAmount = 0;
        auct().startTime = uint64(block.timestamp);
        auct().endTime = uint64(block.timestamp) + acs().auctionDuration;
        auct().highestBidder = address(0);
        auct().settled = false;

        emit AuctionStarted(auct().auctionId, auct().startTime, auct().endTime);
    }
    
    function auctionEnded() public view returns (bool) {
        return block.timestamp >= auct().endTime;
    }
    
    function auctionStarted() public view returns (bool) {
        return auct().startTime != 0 && block.timestamp >= auct().startTime;
    }
    
    function _settleAuction() internal {
        require(auct().startTime != 0, "Auction hasn't begun");
        require(!auct().settled, 'Auction has already been settled');
        require(auctionEnded(), "Auction hasn't completed");

        uint auctionKeyId = slugToTokenId(gs().auctionItemSlug);

        auct().settled = true;

        if (auct().highestBidder != address(0)) {
            _mint(auct().highestBidder, auctionKeyId, 1, "");
        }

        emit AuctionSettled(auct().auctionId, auct().highestBidder, auct().highestBidAmount);
    }
}
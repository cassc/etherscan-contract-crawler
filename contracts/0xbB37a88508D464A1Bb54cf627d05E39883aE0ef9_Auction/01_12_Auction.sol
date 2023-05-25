// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import { AuctionOwnable } from "./utils/AuctionOwnable.sol";
import { ERC165Checker } from "./oz-simplified/ERC165Checker.sol";
import { ECDSA } from "./oz-simplified/ECDSA.sol";
import { IEscrow } from "./interfaces/IEscrow.sol";
import { ISellerToken } from './interfaces/ISellerToken.sol';
import { ReentrancyGuard } from 'solmate/src/utils/ReentrancyGuard.sol';

import { Errors } from "./library/errors/Errors.sol";

enum BidReturnValue {
    Success,
    BidTooLow,
    AuctionClosed,
    ExtendedBidding
}

enum AuctionStatus {
    Closed,
    Open,
    InExtended,
    Ended,
    DoesntExist,
    Cancelled
}

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Auction is AuctionOwnable, ReentrancyGuard {
    event AuctionAdded(uint256 indexed auctionId, uint48 startTime, uint48 endTime, uint256 indexed claimId, uint256 indexed tokenId);
    event AuctionChanged(uint256 indexed auctionId, uint48 startTime, uint48 endTime, uint256 indexed claimId);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint128 indexed bid);
    event AuctionAborted(uint256 indexed auctionId, bool indexed refunded, string reason);
    event AuctionProceedsClaimed(uint256 indexed auctionId, address indexed seller, address recipient, uint128 indexed amount);
    event AuctionLotClaimed(uint256 indexed auctionId, uint256 indexed claimId, address indexed winner, address recipient);
    event AuctionClosed(uint256 indexed auctionId);
    event AuctionInExtendedBidding(uint indexed auctionId);
    event BidTooLow(uint256 indexed auctionId, uint128 indexed bid, uint128 indexed minHighBid);

    event Bid(
        uint256 indexed auctionId,
        uint256 when,
        address indexed bidder,
        uint128 indexed amount
    );

    struct AuctionData {
        uint256 claimId;

        // token that grants seller claim rights to this auction
        uint256 tokenId;

        // when can bidding start
        uint48 startTime;
        // when is auction over
        uint48 endTime;
        // time in seconds that extended bidding lasts
        uint32 extendedBiddingTime;
        // how much does each bid have to increment over the last bid
        uint64 minBidIncrement;
        // is auction active (accepting bids)
        bool active;
        // has the winner claimed
        bool claimed;
        // was the auction cancelled
        bool cancelled;
        // basis points for buyer's premium
        uint8 basis;

        // high bidder
        address highBidder;
        // amount of high bid
        uint64 highBid;
        // last bid timestamp
        // storing as a delta value so we can fit it in fewer bits, optimizing
        // the cost of reading/writing it from storage
        uint32 lastBidDelta;
    }

    IEscrow private _escrow;
    ISellerToken public _sellerToken;

    uint256 private _lastId;

    mapping(uint256 => AuctionData) private _auctions;
    mapping(uint256 => uint256) public _tokenAuctionMap;

    bool private _requireAuctionVerification = true;

    constructor() {
        __Ownable_init();
    }

    // function initialize() public initializer {
    // 	__Ownable_init();
    // }

    function setup(address escrow, address sellerToken_, bool requireAuctionVerification_) public onlyOwner {
        if (!ERC165Checker.supportsInterface(escrow, type(IEscrow).interfaceId)) {
            revert Errors.InterfaceNotSupported();
        }
        _escrow = IEscrow(escrow);
        _requireAuctionVerification = requireAuctionVerification_;
        _sellerToken = ISellerToken(sellerToken_);
    }

    function addAuction(
        uint48 startTime,
        uint48 endTime,
        uint32 extendedBiddingTime,
        uint64 startBid,
        uint64 increment,
        uint8 basis,
        uint256 claimId,
        address seller
    ) public onlyAuctioneer nonReentrant {
        if (endTime < block.timestamp) {
            revert Errors.OutOfRange(endTime);
        }

        uint256 auctionId = ++_lastId;
        uint256 tokenId = _sellerToken.mint(seller, auctionId);

        _auctions[ auctionId ] = AuctionData({
            claimId: claimId,
            tokenId: tokenId,
            startTime: startTime,
            endTime: endTime,
            extendedBiddingTime: extendedBiddingTime,
            minBidIncrement: increment,
            active: true,
            basis: basis,
            lastBidDelta: uint32(0),
            highBidder: address(0),
            highBid: startBid,
            claimed: false,
            cancelled: false
        });
        emit AuctionAdded(auctionId, startTime, endTime, claimId, tokenId);
    }

    function editAuction(
        uint256 auctionId,
        uint48 startTime,
        uint48 endTime,
        uint32 extendedBiddingTime,
        uint64 increment,
        uint8 basis,
        uint256 claimId
    ) public onlyAuctioneer {
        _auctions[auctionId].startTime = startTime;
        _auctions[auctionId].endTime = endTime;
        _auctions[auctionId].extendedBiddingTime = extendedBiddingTime;
        _auctions[auctionId].minBidIncrement = increment;
        _auctions[auctionId].basis = basis;
        _auctions[auctionId].claimId = claimId;

        emit AuctionChanged(auctionId, startTime, endTime, claimId);
    }

    function abortAuction(uint256 auctionId, bool issueRefund, string memory reason) public onlyAuctioneer {
        _auctions[auctionId].active = false;
        _auctions[auctionId].cancelled = true;
        _sellerToken.burn(_auctions[auctionId].tokenId);
        if (issueRefund) {
            address highBidder = _auctions[auctionId].highBidder;
            if (highBidder != address(0)) {
                uint8 basis = _auctions[auctionId].basis;
                uint256 premium = basis == 0 ? 0 : _auctions[auctionId].highBid * basis / 100;
                _escrow.withdraw(highBidder, _auctions[auctionId].highBid + premium);
            }
        }
        emit AuctionAborted(auctionId, issueRefund, reason);
    }

    function claimLot(uint256 auctionId, address deliverTo) public nonReentrant {
        AuctionData storage auction = _auctions[ auctionId ];
        if (_requireAuctionVerification) {
            if ( auction.active ) {
                revert Errors.AuctionActive(auctionId);
            }
        }

        if (block.timestamp < auction.endTime + 1) {
            revert Errors.AuctionActive(auctionId);
        }

        if (_auctionInExtendedBidding(auction)) {
            revert Errors.AuctionActive(auctionId);
        }

        if (auction.cancelled) {
            revert Errors.AuctionAborted(auctionId);
        }

        if (auction.claimed) {
            revert Errors.AlreadyClaimed(auctionId);
        }

        if (_msgSender() != auction.highBidder) {
            revert Errors.BadSender(auction.highBidder, _msgSender());
        }

        if (false == _requireAuctionVerification) {
            _escrow.authorizeClaim(auction.claimId, auction.highBidder);
        }
        auction.claimed = true;
        _escrow.claimFor(_msgSender(), auction.claimId, deliverTo);
        emit AuctionLotClaimed(auctionId, auction.claimId, _msgSender(), deliverTo);
    }

    function claimProceeds(uint256 auctionId, address deliverTo) public nonReentrant {
        AuctionData storage auction = _auctions[ auctionId ];

        if (_requireAuctionVerification) {
            if ( true == auction.active ) {
                revert Errors.AuctionActive(auctionId);
            }
        }

        if (block.timestamp < auction.endTime + 1) {
            revert Errors.AuctionActive(auctionId);
        }

        if (_auctionInExtendedBidding(auction)) {
            revert Errors.AuctionActive(auctionId);
        }

        if (auction.cancelled) {
            revert Errors.AuctionAborted(auctionId);
        }

        address tokenOwner = _sellerToken.ownerOf(auction.tokenId);

        if ( _msgSender() != tokenOwner) {
            revert Errors.BadSender(tokenOwner, _msgSender());
        }

        _sellerToken.burn(auction.tokenId);
        _escrow.withdraw(deliverTo, auction.highBid);
        emit AuctionProceedsClaimed(auctionId, _msgSender(), deliverTo, auction.highBid);
    }

    function confirmAuctions(uint256[] calldata auctionIds, address[] calldata premiumRecipients) public nonReentrant onlyAuctioneer {
        uint256 auctionLength = auctionIds.length;
        if (auctionLength != premiumRecipients.length) {
            revert Errors.ArrayMismatch();
        }

        for (uint i = 0; i < auctionLength;) {
            confirmAuction(auctionIds[ i ], premiumRecipients[ i ]);

            unchecked {
                ++i;
            }
        }
    }

    function confirmAuction(uint256 auctionId, address premiumRecipient) public nonReentrant onlyAuctioneer {
        AuctionData storage auction = _auctions[auctionId];

        if (block.timestamp < auction.endTime + 1) {
            revert Errors.AuctionActive(auctionId);
        }

        if (_auctionInExtendedBidding(auction)) {
            revert Errors.AuctionActive(auctionId);
        }

        if (auction.cancelled) {
            revert Errors.AuctionAborted(auctionId);
        }

        // require auctions to be active to call this method, so we don't
        // double-widthdraw the buyer premium
        if (false == auction.active) {
            revert Errors.AuctionInactive(auctionId);
        }

        auction.active = false;
        emit AuctionEnded(auctionId, auction.highBidder, auction.highBid);

        if (auction.highBidder != address(0)) {
            if (false == auction.claimed && _requireAuctionVerification) {
                _escrow.authorizeClaim(auction.claimId, auction.highBidder);
            }

            if (auction.basis > 0) {
                if (address(0) == premiumRecipient) {
                    revert Errors.AddressTarget(premiumRecipient);
                }

                _escrow.withdraw(premiumRecipient, auction.highBid * auction.basis / 100);
            }
        }
    }

    function getAuctionMetadata(uint256 auctionId) public view returns (AuctionData memory) {
        return _auctions[auctionId];
    }

    function bid(
        uint256 auctionId,
        uint64 amount,
        bool revertOnFail
    ) public nonReentrant {
        _bid(_msgSender(), auctionId, amount, revertOnFail);
    }

    function multiBid(
        uint256[] memory auctionIds,
        uint64[] memory amounts,
        bool revertOnFail
    ) public nonReentrant {
        uint256 arrayLength = auctionIds.length;
        if (arrayLength != amounts.length) {
            revert Errors.ArrayMismatch();
        }

        address bidder = _msgSender();

        for (uint256 i = 0; i < arrayLength;) {
            _bid(bidder, auctionIds[i], amounts[i], revertOnFail);

            unchecked {
                ++i;
            }
        }
    }

    function auctionStatus(uint256 auctionId) public view returns(AuctionStatus) {
        AuctionData storage a = _auctions[ auctionId ];

        if (a.startTime == 0) {
            return AuctionStatus.DoesntExist;
        }

        if (a.cancelled) {
            return AuctionStatus.Cancelled;
        }

        if (block.timestamp < a.startTime) {
            return AuctionStatus.Closed;
        }

        if (block.timestamp < a.endTime + 1) {
            return AuctionStatus.Open;
        }

        if (_auctionInExtendedBidding(a)) {
            return AuctionStatus.InExtended;
        }

        return AuctionStatus.Ended;
    }

    /**
     *  ================== INTERNAL METHODS ====================
     */

    function _bid(
        address bidder,
        uint256 auctionId,
        uint64 amount,
        bool revertOnError
    ) internal returns (BidReturnValue) {
        uint256 timestamp = block.timestamp;
        AuctionData storage auction = _auctions[ auctionId ];
        if (timestamp > auction.endTime) {
            if ( false == _auctionInExtendedBidding(auction)) {
               // auction is over
                if (revertOnError) {
                    revert Errors.AuctionClosed(auctionId);
                }

                emit AuctionClosed(auctionId);
                return BidReturnValue.AuctionClosed;
            }
        }

        if (false == auction.active) {
            if (revertOnError) {
                revert Errors.AuctionClosed(auctionId);
            }

            emit AuctionClosed(auctionId);
            return BidReturnValue.AuctionClosed;
        }

        if (timestamp < auction.startTime) {
            if (revertOnError) {
                revert Errors.AuctionClosed(auctionId);
            }

            emit AuctionClosed(auctionId);
            return BidReturnValue.AuctionClosed;
        }

        uint64 previousAmount = auction.highBid;

        // bid is too low
        if (amount < previousAmount + auction.minBidIncrement) {
            if (revertOnError) {
                revert Errors.BidTooLow(auctionId, amount, previousAmount + auction.minBidIncrement);
            }

            emit BidTooLow(auctionId, amount, previousAmount + auction.minBidIncrement);
            return BidReturnValue.BidTooLow;
        }

        uint256 premium = auction.basis == 0 ? 0 : amount * auction.basis / 100;

        _escrow.deposit(bidder, amount + premium);
        address prevBidder = auction.highBidder;
        if (prevBidder != address(0)) {
            uint256 prevPremium = auction.basis == 0 ? 0 : previousAmount * auction.basis / 100;
            _escrow.withdraw(prevBidder, previousAmount + prevPremium);
        }

        /**
         * There needs to be 2 bidders on a Lot to send it into extended bidding
         * when no bids, bidder == 0x0. first bidder != 0x0, so decrement required count
         * if second bidder != first bidder, decrement required count
         * once we get to zero, we know we'll be going into extended bidding.
         */
        // if (0 < auction.extendedBiddingTime) {
        //     if (0 < auction.extBidRequiredBids) {
        //         if (prevBidder != bidder) {
        //             unchecked {
        //                 // can't overflow, value checked to be above zero, above.
        //                 --auction.extBidRequiredBids;
        //             }
        //         }
        //     }
        // }

        auction.highBidder = bidder;
        auction.highBid = amount;
        // only write the bid-time delta if we're in extended bidding
        // it's irrelevant, otherwise.
        if (auction.endTime < timestamp) {
            auction.lastBidDelta = uint32(timestamp - auction.endTime);
        }

        emit Bid(auctionId, timestamp, bidder, amount);
        return BidReturnValue.Success;
    }

    function _auctionInExtendedBidding(AuctionData storage auction) internal view returns(bool) {
        uint tmpEndTime = auction.endTime;
        if (block.timestamp > auction.endTime) {
            uint tmpExtTime = auction.extendedBiddingTime;
            if (0 < tmpExtTime) {
                uint extendedEndTime = tmpEndTime + tmpExtTime;
                // uint tmpDelta = auction.lastBidDelta;
                if (0 < auction.lastBidDelta) {
                    extendedEndTime = tmpEndTime + auction.lastBidDelta + tmpExtTime;
                }

                /*
                * auction is over if we're past the extended bidding time, no matter what
                *
                * or
                *
                * we require 2+ bids to enter extended bidding. so, if we're past the auction endTime (tested above)
                * and we need more than 0 bids to enter extended bidding
                * (required bids is decremented from 2 to 0 on the first two bids)
                * then we never went into extended bidding, and thus, the auction is over
                **/
                if (block.timestamp > extendedEndTime) {
                    // auction is over
                    return false;
                }

                // if we get here, then current timestamp is between endTime and extendedEndTime
                // and aucton.extBidRequireBids == 0
                return true;
            }
        }

        return false;
    }
}
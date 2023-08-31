// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error InputMismatch();
error AuctionNotStarted();
error MaxPerMintExceeded();
error InsufficientPrice();
error WithdrawFailed();
error InvalidCurrentTokenId();
error RefundAlreadyProcessed();
error AuctionNotOver();
error InvalidBid();
error RefundFailed(uint256 tokenId);
error OnlyEOA();

contract EtherCapsuleAuction is Ownable, ReentrancyGuard {
    IERC721 public immutable ETHER_CAPSULE;

    struct AuctionParams {
        uint64 startPrice;
        uint64 endPrice;
        uint64 decay;
        uint32 step;
        uint32 startTime;
    }

    struct Bid {
        address bidder;
        uint64 amount;
        bool refundProcessed;
    }

    AuctionParams public auctionParams;
    mapping(uint256 => Bid) public tokenBids;
    // Initial value is the first token minted to this contract
    uint256 public currentTokenId = 2075;
    uint256 public finalTokenId = 5555;
    uint256 public settlePrice;

    constructor(
        address _capsuleAddress,
        uint64 _startPrice,
        uint64 _endPrice,
        uint64 _decay,
        uint32 _step,
        uint32 _startTime
    ) {
        ETHER_CAPSULE = IERC721(_capsuleAddress);

        auctionParams = AuctionParams(_startPrice, _endPrice, _decay, _step, _startTime);
    }

    function airdrop(address[] calldata receivers, uint16[] calldata amounts) external onlyOwner {
        if (receivers.length != amounts.length) revert InputMismatch();

        unchecked {
            for (uint256 i; i < receivers.length; ++i) {
                address receiver = receivers[i];
                uint16 amount = amounts[i];
                uint256 _currentTokenId = currentTokenId;

                // Loop through and transfer tokens
                for (uint16 j; j < amount; ++j) {
                    ETHER_CAPSULE.transferFrom(address(this), receiver, _currentTokenId + j);
                }

                currentTokenId += amount;
            }
        }
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert OnlyEOA();
        _;
    }

    // =========================================================================
    //                            Auction Functions
    // =========================================================================

    function getAuctionPrice() public view returns (uint256) {
        AuctionParams memory _auctionParams = auctionParams;
        if (_auctionParams.startTime == 0) return _auctionParams.startPrice;
        uint256 elapsed = block.timestamp - _auctionParams.startTime;
        uint256 steps = elapsed / _auctionParams.step;
        uint256 decay = steps * _auctionParams.decay;
        unchecked {
            if (decay > _auctionParams.startPrice - _auctionParams.endPrice) {
                return _auctionParams.endPrice;
            }
            return _auctionParams.startPrice - decay;
        }
    }

    function auctionMint(uint256 qty) external payable nonReentrant onlyEOA {
        if (auctionParams.startTime == 0) revert AuctionNotStarted();
        if (qty > 3) revert MaxPerMintExceeded();

        uint256 currentPrice = getAuctionPrice();
        uint256 totalPrice = currentPrice * qty;
        if (msg.value < totalPrice) revert InsufficientPrice();

        // Record bids for each token id
        uint256 _currentTokenId = currentTokenId;
        for (uint256 i; i < qty;) {
            uint256 tokenId = _currentTokenId + i;
            tokenBids[tokenId] = Bid(msg.sender, uint64(currentPrice), false);
            ETHER_CAPSULE.transferFrom(address(this), msg.sender, tokenId);
            unchecked {
                ++i;
            }
        }

        unchecked {
            // Increment current token id
            currentTokenId += qty;

            // Set final settlement price if last token id has been minted
            if (currentTokenId == finalTokenId) {
                settlePrice = currentPrice;
            }

            // Refund if over
            uint256 difference = msg.value - totalPrice;
            if (difference > 0) {
                _transferETH(msg.sender, difference);
            }
        }
    }

    function processRefunds(uint256[] calldata tokenIds) external nonReentrant {
        if (currentTokenId != finalTokenId) revert AuctionNotOver();

        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            Bid memory bid = tokenBids[tokenId];

            if (bid.bidder == address(0)) revert InvalidBid();
            if (bid.refundProcessed) revert RefundAlreadyProcessed();

            tokenBids[tokenId].refundProcessed = true;
            uint256 priceDifference = bid.amount - settlePrice;
            if (priceDifference > 0) {
                bool success = _transferETH(bid.bidder, priceDifference);
                if (!success) revert RefundFailed(tokenId);
            }

            unchecked {
                ++i;
            }
        }
    }

    // =========================================================================
    //                           Owner Only Functions
    // =========================================================================

    function setCurrentTokenId(uint256 _currentTokenId) external onlyOwner {
        if (ETHER_CAPSULE.ownerOf(_currentTokenId) != address(this)) {
            revert InvalidCurrentTokenId();
        }
        currentTokenId = _currentTokenId;
    }

    function setFinalTokenId(uint256 _finalTokenId) external onlyOwner {
        finalTokenId = _finalTokenId;
    }

    function setAuctionStart(uint32 _startTime) external onlyOwner {
        auctionParams.startTime = _startTime;
    }

    function setAuctionParams(uint64 _startPrice, uint64 _endPrice, uint64 _decay, uint32 _step, uint32 _startTime)
        external
        onlyOwner
    {
        // Passing a _startTime > 0 will set the auction start time
        auctionParams = AuctionParams(_startPrice, _endPrice, _decay, _step, _startTime);
    }

    function withdrawFunds(address receiver) external onlyOwner {
        (bool sent,) = receiver.call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success,) = to.call{value: value, gas: 30000}(new bytes(0));
        return success;
    }
}
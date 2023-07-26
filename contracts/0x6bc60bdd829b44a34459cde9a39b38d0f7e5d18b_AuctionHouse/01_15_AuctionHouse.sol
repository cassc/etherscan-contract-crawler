/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAuctionHouse.sol";
import "./WithTreasury.sol";
import "hardhat/console.sol";

contract AuctionHouse is IAuctionHouse, WithTreasury, ERC1155Holder, AccessControl, ReentrancyGuard {
    bytes32 public constant AUCTIONABLE_ROLE = keccak256("AUCTIONABLE_ROLE");
    bytes32 public constant AUCTION_CREATOR_ROLE = keccak256("AUCTION_CREATOR_ROLE");

    /// @dev seller => Auctions
    mapping(address => Auction[]) private _auctions;

    uint256 public minBidIncrement;

    constructor(
        uint256 minBidIncrement_,
        address payable modaTreasury_,
        uint256 treasuryFee_
    ) WithTreasury(modaTreasury_, treasuryFee_) {
        require(treasuryFee_ > 0, "Treasury fee cannot be 0");

        _setMinBidIncrement(minBidIncrement_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AUCTION_CREATOR_ROLE, msg.sender);
    }

    function createAuction(
        address tokenHolder,
        address payable beneficiary,
        address token,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 startAt,
        uint256 endAt,
        uint256 startingBid
    ) external override onlyRole(AUCTION_CREATOR_ROLE) {
        require(hasRole(AUCTIONABLE_ROLE, address(token)), "Token not auctionable");
        require(address(0) != beneficiary, "Beneficiary cannot be 0x0");
        require(startAt < endAt, "Start must be before end");
        require(startAt >= block.timestamp, "Must start in the future");
        require(tokenAmount > 0, "Must specify token amount");

        IERC1155(token).safeTransferFrom(tokenHolder, address(this), tokenId, tokenAmount, "");

        _auctions[msg.sender].push(
            Auction({
                tokenHolder: tokenHolder,
                beneficiary: beneficiary,
                token: token,
                tokenId: tokenId,
                tokenAmount: tokenAmount,
                startAt: startAt,
                endAt: endAt,
                ended: false,
                highestBidder: address(0),
                highestBid: startingBid
            })
        );

        emit AuctionCreated(msg.sender, _auctions[msg.sender].length - 1);
    }

    function bid(address seller, uint256 auctionIndex) external payable override nonReentrant {
        Auction storage auction = _auctions[seller][auctionIndex];
        require(address(0) != auction.token, "Auction not found");
        require(auction.startAt <= block.timestamp, "Auction has not started yet");
        require(auction.endAt > block.timestamp, "Auction has ended");
        require(msg.value >= auction.highestBid + minBidIncrement, "Insufficient bid amount");

        uint256 remainingTime = auction.endAt - block.timestamp;
        if (remainingTime < 1_800) auction.endAt = block.timestamp + 1_800;

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit Bid(seller, auctionIndex, msg.sender, msg.value, block.timestamp);
    }

    function claim(address seller, uint256 auctionId) external override {
        Auction storage auction = _auctions[seller][auctionId];
        require(!auction.ended, "Already ended");

        if (block.timestamp < auction.startAt) {
            require(_msgSender() == seller, "Unauthorized");
        } else {
            require(block.timestamp > auction.endAt, "Auction has not ended");
        }

        auction.ended = true;
        if (address(0) != auction.highestBidder) {
            IERC1155(auction.token).safeTransferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId,
                auction.tokenAmount,
                ""
            );

            uint256 fee = (treasuryFee * auction.highestBid) / 10000;
            modaTreasury.transfer(fee);
            auction.beneficiary.transfer(auction.highestBid - fee);

            emit AuctionItemClaimed(
                auction.highestBidder,
                auction.token,
                auction.tokenId,
                auction.tokenAmount,
                auction.highestBid
            );
        } else {
            IERC1155(auction.token).safeTransferFrom(
                address(this),
                auction.tokenHolder,
                auction.tokenId,
                auction.tokenAmount,
                ""
            );
            emit AuctionItemClaimed(auction.tokenHolder, auction.token, auction.tokenAmount, auction.tokenId, 0);
        }
    }

    function auctionAt(address seller, uint256 index) external view override returns (Auction memory) {
        return _auctions[seller][index];
    }

    function auctionCount(address seller) external view override returns (uint256) {
        return _auctions[seller].length;
    }

    function setMinBidIncrement(uint256 newMinBidIncrement) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMinBidIncrement(newMinBidIncrement);
    }

    function setTreasuryFee(uint256 newFee_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTreasuryFee(newFee_);
    }

    function setTreasury(address payable newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTreasury(newTreasury);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _setMinBidIncrement(uint256 newMinBidIncrement) private {
        require(newMinBidIncrement > 0, "Min bid increment must be gt 0");

        uint256 old = minBidIncrement;
        minBidIncrement = newMinBidIncrement;

        emit MinBidIncrementSet(old, newMinBidIncrement);
    }
}
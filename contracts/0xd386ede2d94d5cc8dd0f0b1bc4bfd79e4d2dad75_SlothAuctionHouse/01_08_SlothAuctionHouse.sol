// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// LICENSE
// SlothAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Sloth.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ISlothAuctionHouse } from "./interfaces/ISlothAuctionHouse.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

contract SlothAuctionHouse is ISlothAuctionHouse, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;

  // The minimum amount of time left in an auction after a new bid is created
  uint256 public defaultTimeBuffer = 300; // 5min

  // Offset time for auction closing time (Based on UTC+0)
  uint256 public endTimeOffset = 3600 * 12;

  // The minimum price accepted in an auction
  uint256 public defaultReservePrice = 10000000000000000; // 0.01eth

  // The minimum percentage difference between the last bid amount and the current bid
  uint8 public defaultMinBidIncrementPercentage = 2; // 2%

  bool public paused = true;

  address private _treasuryAddress = 0x452Ccc6d4a818D461e20837B417227aB70C72B56;

  Counters.Counter private _auctionIdTracker;
  mapping(uint256 => ISlothAuctionHouse.Auction) public auctions;
  uint256[] private _currentAuctions;

  /**
    * @notice Require that the specified auction exists
    */
  modifier auctionExists(uint256 auctionId) {
    require(_exists(auctionId), "Auction doesn't exist");
    _;
  }

  function _exists(uint256 auctionId) internal view returns(bool) {
    return auctions[auctionId].tokenContract != address(0);
  }


  function settleAuction(uint256 _auctionId) external onlyOwner {
    _settleAuction(_auctionId);
  }

  function pause() external onlyOwner {
      _pause();
  }

  function unpause() external onlyOwner {
      _unpause();
  }

  function setTimeBuffer(uint256 _auctionId, uint256 _timeBuffer) external onlyOwner {
      auctions[_auctionId].timeBuffer = _timeBuffer;
  }

  function setReservePrice(uint256 _auctionId, uint256 _reservePrice) external onlyOwner {
    auctions[_auctionId].reservePrice = _reservePrice;
  }

  function setMinBidIncrementPercentage(uint256 _auctionId, uint8 _minBidIncrementPercentage) external onlyOwner {
    auctions[_auctionId].minBidIncrementPercentage = _minBidIncrementPercentage;
  }

  function setEndTimeOffset(uint256 _endTimeOffset) external onlyOwner {
    endTimeOffset = _endTimeOffset;
  }

  function setTreasuryAddress(address treasuryAddress) external onlyOwner {
    _treasuryAddress = treasuryAddress;
  }

  function createAuction(uint256 tokenId, address tokenContract, uint256 startTime, uint256 endTime) external onlyOwner nonReentrant returns (uint256) {
    require(startTime < endTime, "start must be before end");
    require(startTime > block.timestamp, "start must be in the future");
    require(msg.sender == IERC721(tokenContract).ownerOf(tokenId), "sender must be token owner");
    require(
      IERC721(tokenContract).getApproved(tokenId) == address(this) || IERC721(tokenContract).isApprovedForAll(msg.sender, address(this)),
      "tokenContract is not approved"
    );

    uint256 auctionId = _auctionIdTracker.current();

    auctions[auctionId] = ISlothAuctionHouse.Auction({
      tokenId: tokenId,
      tokenOwner: msg.sender,
      tokenContract: tokenContract,
      amount: 0,
      timeBuffer: defaultTimeBuffer,
      reservePrice: defaultReservePrice,
      minBidIncrementPercentage: defaultMinBidIncrementPercentage,
      bidder: payable(0),
      startTime: startTime,
      endTime: endTime,
      settled: false
    });
    _currentAuctions.push(auctionId);
    _auctionIdTracker.increment();
    emit AuctionCreated(auctionId, tokenId, msg.sender, tokenContract, startTime, endTime);
    return auctionId;
  }

  function currentAuctions() external view returns (uint256[] memory) {
    uint[] memory arr = new uint256[](_currentAuctions.length);
    arr = _currentAuctions;
    return arr;
  }

  function createBid(uint256 _auctionId, uint256 amount) external payable auctionExists(_auctionId) nonReentrant {
    // auctionのendTimeを過ぎていないことを確認
    require(!auctions[_auctionId].settled, "Auction has already been settled");
    require(block.timestamp < auctions[_auctionId].endTime, "Auction expired");
    require(block.timestamp >= auctions[_auctionId].startTime, "not started");
    require(amount >= auctions[_auctionId].reservePrice, "Must send at least reservePrice");
    require(
      msg.value >= auctions[_auctionId].amount + ((auctions[_auctionId].amount * auctions[_auctionId].minBidIncrementPercentage) / 100),
      'Must send more than last bid by minBidIncrementPercentage amount'
    );

    address payable lastBidder = auctions[_auctionId].bidder;
    if (lastBidder != address(0)) {
      _safeTransferETHWithFallback(lastBidder, auctions[_auctionId].amount);
    }

    auctions[_auctionId].amount = msg.value;
    auctions[_auctionId].bidder = payable(msg.sender);
    bool extended = auctions[_auctionId].endTime - block.timestamp < auctions[_auctionId].timeBuffer;
    if (extended) {
      auctions[_auctionId].endTime = block.timestamp + auctions[_auctionId].timeBuffer;
    }
    emit AuctionBid(_auctionId, auctions[_auctionId].tokenId, auctions[_auctionId].tokenContract, msg.sender, msg.value, extended);

    if (extended) {
      emit AuctionExtended(_auctionId, auctions[_auctionId].endTime);
    }
  }

  function _settleAuction(uint256 _auctionId) internal onlyOwner auctionExists(_auctionId) nonReentrant {
    ISlothAuctionHouse.Auction memory auction = auctions[_auctionId];
    require(block.timestamp > auction.endTime, "Auction hasn't completed yet");
    require(!auction.settled, "Auction has already been settled");
    auctions[_auctionId].settled = true;

    if (auction.bidder != payable(0)) {
      IERC721(auction.tokenContract).safeTransferFrom(auction.tokenOwner, auction.bidder, auction.tokenId);
    }

    if (auction.amount > 0) {
      _safeTransferETHWithFallback(_treasuryAddress, auction.amount);
    }

    emit AuctionSettled(_auctionId, auction.bidder, auction.amount);
  }

  function cancelAuction(uint256 auctionId) external onlyOwner nonReentrant auctionExists(auctionId) {
    if (auctions[auctionId].bidder != payable(0) && !auctions[auctionId].settled) {
      revert("already bidded");
    }
    _cancelAuction(auctionId);
  }

  function _cancelAuction(uint256 auctionId) internal {
    emit AuctionCanceled(auctionId, auctions[auctionId].tokenId, auctions[auctionId].tokenContract);
    delete auctions[auctionId];
  }

  /**
    * @notice Transfer ETH. If the ETH transfer fails,send to Owner.
    */
  function _safeTransferETHWithFallback(address to, uint256 amount) internal {
    if (!_safeTransferETH(to, amount)) {
      require(_safeTransferETH(owner(), amount), "receiver rejected ETH transfer");
    }
  }

  /**
    * @notice Transfer ETH and return the success status.
    * @dev This function only forwards 30,000 gas to the callee.
    */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
    return success;
  }

  function _pause() internal {
      paused = true;
  }

  function _unpause() internal {
      paused = false;
  }

  function owner() public view override returns (address) {
    return super.owner();
  }
}
// SPDX-License-Identifier: GPL-3.0

// LICENSE
// RaidersAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol and Nouns DAO's NounsAuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// RaidersAuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// NounsAuctionHouse.sol source code Copyright Nouns DAO licensed under the GPL-3.0 license.
// With modifications by Skullx

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IAuctionHouse.sol";
import "../common/erc20/IWETH.sol";
import "../common/erc721/IERC721Sale.sol";

contract RaidersAuctionHouse is
  Context,
  IERC165,
  AccessControl,
  IAuctionHouse,
  ReentrancyGuard,
  ERC1155Receiver,
  IERC721Receiver
{
  using ERC165Checker for address;
  using Counters for Counters.Counter;

  // The address of the WETH contract
  address public weth;

  // The minimum amount of time left in an auction after a new bid is created
  uint256 public timeBuffer;

  // The minimum price accepted in an auction
  uint256 public reservePrice;

  // The minimum percentage difference between the last bid amount and the current bid
  uint8 public minBidIncrementPercentage;

  // The duration of a single auction
  uint256 public duration;

  // ID of the active auction
  Counters.Counter public _auctionIdTracker;

  // Mapping of all auctions
  mapping(uint256 => Auction) auctions;

  // Cyber Raiders contract
  IERC721Sale public cyberRaiders;

  modifier noBids() {
    Auction storage auction = auctions[_auctionIdTracker.current()];
    require(auction.settled || auction.amount == 0, "active auction has bids");
    _;
  }

  constructor(
    address _weth,
    uint256 _timeBuffer,
    uint256 _reservePrice,
    uint8 _minBidIncrementPercentage,
    uint256 _duration,
    address _cyberRaiders
  ) {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

    weth = _weth;
    timeBuffer = _timeBuffer;
    reservePrice = _reservePrice;
    minBidIncrementPercentage = _minBidIncrementPercentage;
    duration = _duration;
    cyberRaiders = IERC721Sale(_cyberRaiders);
  }

  /**
   * @notice Settle the current auction.
   */
  function settleAuction() external override nonReentrant {
    _settleAuction();
  }

  /**
   * @notice Create a bid for an NFT, with a given amount.
   * @dev This contract only accepts payment in ETH.
   */
  function createBid() external payable nonReentrant {
    uint256 auctionId = _auctionIdTracker.current();
    Auction storage auction = auctions[auctionId];

    require(auction.endTime != 0 && auction.startTime != 0, "no auction");
    require(block.timestamp > auction.startTime, "auction not started");
    require(block.timestamp < auction.endTime, "auction expired");
    require(
      msg.value >= reservePrice && msg.value > 0,
      "bid is lower than reserve price"
    );
    require(
      msg.value >=
        auction.amount + ((auction.amount * minBidIncrementPercentage) / 100),
      "bid is lower than increment from last bid"
    );

    address payable lastBidder = auction.bidder;

    // Refund the last bidder, if applicable
    _safeTransferETHWithFallback(lastBidder, auction.amount);

    auction.amount = msg.value;
    auction.bidder = payable(_msgSender());
    auction.lastBidBlock = block.number;

    // Extend the auction if the bid was received within `timeBuffer` of the auction end time
    bool extended = auction.endTime - block.timestamp < timeBuffer;
    if (extended) {
      auction.endTime = auction.endTime = block.timestamp + timeBuffer;
    }

    emit AuctionBid(
      auctionId,
      auction.token,
      auction.tokenId,
      _msgSender(),
      msg.value,
      extended
    );

    if (extended) {
      emit AuctionExtended(
        auctionId,
        auction.token,
        auction.tokenId,
        auction.endTime
      );
    }
  }

  /**
   * @notice Creates an auction.
   * @dev Only callable by DEFAULT_ADMIN_ROLE.
   */
  function createAuction(
    address from,
    address token,
    uint256 tokenId,
    uint256 startTime,
    address payable treasury
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _createAuction(from, token, tokenId, startTime, treasury);
  }

  /**
   * @notice Cancels the current auction if no active bids.
   * @dev Only callable by DEFAULT_ADMIN_ROLE. Settles the auction.
   */
  function cancelAuction() external override onlyRole(DEFAULT_ADMIN_ROLE) {
    Auction storage auction = auctions[_auctionIdTracker.current()];
    require(auction.amount == 0, "auction has bids");

    auction.endTime = 0;
    _settleAuction();
  }

  /**
   * @notice Set the auction time buffer.
   * @dev Only callable by DEFAULT_ADMIN_ROLE.
   */
  function setTimeBuffer(
    uint256 _timeBuffer
  ) external override noBids onlyRole(DEFAULT_ADMIN_ROLE) {
    timeBuffer = _timeBuffer;

    emit AuctionTimeBufferUpdated(_timeBuffer);
  }

  /**
   * @notice Set the auction reserve price.
   * @dev Only callable by DEFAULT_ADMIN_ROLE.
   */
  function setReservePrice(
    uint256 _reservePrice
  ) external override noBids onlyRole(DEFAULT_ADMIN_ROLE) {
    reservePrice = _reservePrice;

    emit AuctionReservePriceUpdated(_reservePrice);
  }

  /**
   * @notice Set the auction minimum bid increment percentage.
   * @dev Only callable by DEFAULT_ADMIN_ROLE.
   */
  function setMinBidIncrementPercentage(
    uint8 _minBidIncrementPercentage
  ) external override noBids onlyRole(DEFAULT_ADMIN_ROLE) {
    minBidIncrementPercentage = _minBidIncrementPercentage;

    emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
  }

  /**
   * @notice Checks if address has valid ERC1155 contract.
   */
  function _isERC1155(address nftAddress) internal view returns (bool) {
    return nftAddress.supportsInterface(type(IERC1155).interfaceId);
  }

  /**
   * @notice Checks if address has valid ERC721 contract.
   */
  function _isERC721(address nftAddress) internal view returns (bool) {
    return nftAddress.supportsInterface(type(IERC721).interfaceId) || nftAddress == address(cyberRaiders);
  }

  /**
   * @notice Checks if address has valid token balance.
   */
  function _validBalance(
    address owner,
    address token,
    uint256 tokenId
  ) internal view returns (bool) {
    if (_isERC1155(token)) {
      return IERC1155(token).balanceOf(owner, tokenId) >= 1;
    }
    if (_isERC721(token)) {
      return IERC721(token).ownerOf(tokenId) == owner;
    }
    return false;
  }

  /**
   * @notice Creates an auction.
   * @dev Store the auction details in the `auctions` mapping and emit an AuctionCreated event.
   */
  function _createAuction(
    address from,
    address token,
    uint256 tokenId,
    uint256 startTime,
    address payable treasury
  ) internal {
    uint256 currentAuctionId = _auctionIdTracker.current();
    Auction storage currentAuction = auctions[currentAuctionId];
    require(
      currentAuction.settled || currentAuctionId == 0,
      "current auction not settled"
    );

    require(
      from == _msgSender() || from == address(this),
      "not sender or auction address"
    );

    if (from == _msgSender()) {
      _safeTransferSingleToken(token, from, address(this), tokenId);
    }

    require(_validBalance(address(this), token, tokenId), "no token");

    uint256 start;

    if (startTime < block.timestamp) {
      start = block.timestamp;
    } else {
      start = startTime;
    }

    uint256 endTime = start + duration;

    _auctionIdTracker.increment();
    uint256 auctionId = _auctionIdTracker.current();
    Auction storage auction = auctions[auctionId];

    auction.token = token;
    auction.tokenId = tokenId;
    auction.isERC721 = _isERC721(token);
    auction.amount = 0;
    auction.startTime = start;
    auction.endTime = endTime;
    auction.bidder = payable(_msgSender());
    auction.settled = false;
    auction.treasury = treasury;
    auction.startBlock = block.number;
    auction.lastBidBlock = block.number;

    emit AuctionCreated(auctionId, token, tokenId, startTime, endTime);
  }

  /**
   * @notice Safe transfers a single token.
   * @dev Supports both ERC1155 and ERC721 standard.
   */
  function _safeTransferSingleToken(
    address token,
    address from,
    address to,
    uint256 id
  ) internal {
    require(to != address(0), "can't transfer to 0 address");
    require(_validBalance(from, token, id), "no token");

    if (_isERC721(token)) {
      IERC721(token).safeTransferFrom(from, to, id);
    } else {
      IERC1155(token).safeTransferFrom(from, to, id, 1, "");
    }
  }

  /**
   * @notice Returns the current auction.
   */
  function getCurrentAuction() external view override returns (Auction memory) {
    return auctions[_auctionIdTracker.current()];
  }

  /**
   * @notice Checks if auction is ready to settle.
   */
  function isReadyToSettle() external view returns (bool) {
    Auction storage auction = auctions[_auctionIdTracker.current()];

    return
      auction.startTime != 0 &&
      !auction.settled &&
      block.timestamp >= auction.endTime;
  }

  /**
   * @notice Checks if auction is ready for bids.
   */
  function isReadyToBid() external view returns (bool) {
    Auction storage auction = auctions[_auctionIdTracker.current()];

    return
      auction.endTime != 0 &&
      auction.startTime != 0 &&
      block.timestamp > auction.startTime &&
      block.timestamp < auction.endTime;
  }

  /**
   * @notice Returns time until auction starts in seconds.
   */
  function timeUntilStart() external view returns (uint256) {
    Auction storage auction = auctions[_auctionIdTracker.current()];

    return
      auction.startTime > block.timestamp
        ? auction.startTime - block.timestamp
        : 0;
  }

  /**
   * @notice Returns time left of the auction in seconds.
   */
  function timeLeft() external view returns (uint256) {
    Auction storage auction = auctions[_auctionIdTracker.current()];

    return
      auction.endTime > block.timestamp ? auction.endTime - block.timestamp : 0;
  }

  /**
   * @notice Settle an auction, finalizing the bid and paying out to the owner.
   */
  function _settleAuction() internal {
    uint256 auctionId = _auctionIdTracker.current();
    Auction storage auction = auctions[auctionId];

    require(auction.startTime != 0, "no auction");
    require(!auction.settled, "already settled");
    require(block.timestamp >= auction.endTime, "not completed");

    auction.settled = true;

    _safeTransferSingleToken(
      auction.token,
      address(this),
      auction.bidder,
      auction.tokenId
    );

    _safeTransferETHWithFallback(auction.treasury, auction.amount);

    emit AuctionSettled(
      auctionId,
      auction.token,
      auction.tokenId,
      auction.bidder,
      auction.amount
    );
  }

  /**
   * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
   */
  function _safeTransferETHWithFallback(address to, uint256 amount) internal {
    if (amount == 0 || to == address(0)) {
      return;
    }
    if (!_safeTransferETH(to, amount)) {
      IWETH(weth).deposit{value: amount}();
      IERC20(weth).transfer(to, amount);
    }
  }

  /**
   * @notice Transfer ETH and return the success status.
   * @dev This function only forwards 30,000 gas to the callee.
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
    return success;
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(IERC165, AccessControl, ERC1155Receiver)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
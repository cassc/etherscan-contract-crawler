/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./Fee1155NFTLockable.sol";

/**
  @title A simple NFT auction contract which sells a single item on reserve.
  @author SuperFarm

  This auction contract accepts on-chain bids before minting an NFT to the
  winner.
*/
contract SuperAuctionReserve is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  /// The beneficiary of the auction sale.
  address payable public beneficiary;

  /// The original owner of the NFT contract.
  address public originalOwner;

  /// The item being auctioned.
  Fee1155NFTLockable public item;

  /// The group ID within the item collection being auctioned for.
  uint256 public groupId;

  /// The time at which the auction ends.
  uint256 public auctionEndTime;

  /// The buffer duration within which we extend auctions.
  uint256 public bidBuffer;

  /// The address of the current highest bidder.
  address public highestBidder;

  /// The current highest bid.
  uint256 public highestBid;

  /// The timestamp when the current highest bid was placed.
  uint256 public highestBidTime;

  /// The minimum price for the item sale.
  uint256 public reservePrice;

  /// A mapping of prior bids for users to withdraw.
  mapping (address => uint256) public pendingReturns;

  /// Whether or not the auction has ended.
  bool public ended;

  /// An event to track an increase of the current highest bid.
  event HighestBidIncreased(address bidder, uint256 amount, uint256 timestamp);

  /// An event to track the auction ending.
  event AuctionEnded(address winner, uint256 amount, uint256 timestamp, bool success);

  /// An event to track the original item contract owner clawing back ownership.
  event OwnershipClawback();

  /// @dev a modifier which allows only `originalOwner` to call a function.
  modifier onlyOriginalOwner() {
    require(originalOwner == _msgSender(),
      "You are not the original owner of this contract.");
    _;
  }

  /**
    Construct a new auction by providing it with a beneficiary, NFT item, item
    group ID, and bidding time.

    @param _beneficiary An address for the auction beneficiary to receive funds.
    @param _item The Fee1155NFTLockable contract for the NFT collection being
      bid on.
    @param _groupId The group ID of the winning item within the NFT collection
      specified in `_item`.
    @param _duration The duration of the auction in seconds.
    @param _bidBuffer The buffer time at which a bid will extend the auction.
    @param _reservePrice The reserve price for the bid.
  */
  constructor(address payable _beneficiary, Fee1155NFTLockable _item, uint256 _groupId, uint256 _duration, uint256 _bidBuffer, uint256 _reservePrice) public {
    beneficiary = _beneficiary;
    originalOwner = _item.owner();
    item = _item;
    groupId = _groupId;
    auctionEndTime = block.timestamp + _duration;
    bidBuffer = _bidBuffer;
    reservePrice = _reservePrice;
  }

  /**
    Bid on the auction with the value sent together with this transaction. The
    value will only be refunded if the auction is not won.
  */
  function bid() public payable nonReentrant {
    require(block.timestamp <= auctionEndTime, "Auction already ended.");
    require(msg.value > highestBid, "There already is a higher bid.");

    // Extend the auction if a bid comes in within the ending buffer.
    uint256 timeRemaining = auctionEndTime.sub(block.timestamp);
    if (timeRemaining < bidBuffer) {
      auctionEndTime = auctionEndTime.add(bidBuffer);
    }

    if (highestBid != 0) {
      pendingReturns[highestBidder] += highestBid;
    }
    highestBidder = msg.sender;
    highestBid = msg.value;
    highestBidTime = block.timestamp;
    emit HighestBidIncreased(msg.sender, msg.value, block.timestamp);
  }

  /**
    Withdraw a bid that was defeated.
  */
  function withdraw() public nonReentrant returns (bool) {
    uint256 amount = pendingReturns[msg.sender];
    if (amount > 0) {
      pendingReturns[msg.sender] = 0;
			(bool withdrawSuccess, ) = payable(msg.sender).call{ value: amount }("");
				if (!withdrawSuccess) {
        pendingReturns[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }

  /**
    End the auction. Send the highest bid to the beneficiary and mint the winner
    an NFT item. If the reserve price was not met, return the highest bid.
  */
  function auctionEnd() public nonReentrant {
    require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
    require(!ended, "The auction has already ended.");
    ended = true;

    // If the reserve price is not met, return the highest bid.
    if (reservePrice >= highestBid) {
			(bool bidderReturnSuccess, ) = payable(highestBidder).call{ value: highestBid }("");


      // The auction ended in failure.
      emit AuctionEnded(highestBidder, highestBid, block.timestamp, false);

    // Otherwise, take the highest bid and mint the item.
    } else {
			(bool beneficiarySendSuccess, ) = payable(highestBidder).call{ value: highestBid }("");

      // Mint the items.
      uint256[] memory itemIds = new uint256[](1);
      uint256[] memory amounts = new uint256[](1);
      uint256 shiftedGroupId = groupId << 128;
      uint256 itemId = shiftedGroupId.add(1);
      itemIds[0] = itemId;
      amounts[0] = 1;
      item.createNFT(highestBidder, itemIds, amounts, "");

      // The auction ended in a sale.
      emit AuctionEnded(highestBidder, highestBid, block.timestamp, true);
    }
  }

  /**
    A function which allows the original owner of the item contract to revoke
    ownership from the launchpad.
  */
  function ownershipClawback() external onlyOriginalOwner {
    item.transferOwnership(originalOwner);

    // Emit an event that the original owner of the item contract has clawed the contract back.
    emit OwnershipClawback();
  }
}
/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./Fee1155NFTLockable.sol";

/**
  @title A simple NFT auction contract which sells a single item for an owner to
    accept or decline via highest bid offer.
  @author SuperFarm

  This auction contract accepts on-chain bids before minting an NFT to the
  winner.
*/
contract SuperAuctionAccept is Ownable, ReentrancyGuard {
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

  /// The buffer duration required to return the highest bid if no action taken.
  uint256 public receiptBuffer;

  /// The address of the current highest bidder.
  address public highestBidder;

  /// The current highest bid.
  uint256 public highestBid;

  /// The timestamp when the current highest bid was placed.
  uint256 public highestBidTime;

  /// The minimum bid allowed
  uint256 public minimumBid;

  /// Whether or not the auction has ended.
  bool public ended;

  /// An event to track an increase of the current highest bid.
  event HighestBidIncreased(address bidder, uint256 amount, uint256 timestamp);

  /// An event to track the auction ending.
  event AuctionEnded(address winner, uint256 amount, uint256 timestamp, bool success);

  /// An event to track the auction expiring.
  event AuctionExpired(address winner, uint256 amount, uint256 timestamp);

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
    @param _receiptBuffer The buffer time which the auction owner has to accept.
    @param _minimumBid The lowest starting bid for the auctioned item.
  */
  constructor(address payable _beneficiary, Fee1155NFTLockable _item, uint256 _groupId, uint256 _duration, uint256 _bidBuffer, uint256 _receiptBuffer, uint256 _minimumBid) public {
    beneficiary = _beneficiary;
    originalOwner = _item.owner();
    item = _item;
    groupId = _groupId;
    auctionEndTime = block.timestamp + _duration;
    bidBuffer = _bidBuffer;
    receiptBuffer = _receiptBuffer;
    minimumBid = _minimumBid;
  }

  /**
    Bid on the auction with the value sent together with this transaction. The
    value will only be refunded if the auction is not won.
  */
  function bid() public payable nonReentrant {
    require(block.timestamp <= auctionEndTime, "Auction already ended.");
    require(msg.value > highestBid, "There already is a higher bid.");
    require(msg.value >= minimumBid, "Minimum bid amount not met.");

    // Extend the auction if a bid comes in within the ending buffer.
    uint256 timeRemaining = auctionEndTime.sub(block.timestamp);
    if (timeRemaining < bidBuffer) {
      auctionEndTime = auctionEndTime.add(bidBuffer);
    }

    // The previous highest bidder has been outbid. Return their bid.
    /// @dev We are intentionally not validating success on this payment call
    /// in order to prevent a potential attacker from halting the auction.
    if (highestBid != 0) {
      payable(highestBidder).call{ value: highestBid }("");
    }

    // Update the highest bidder.
    highestBidder = msg.sender;
    highestBid = msg.value;
    highestBidTime = block.timestamp;
    emit HighestBidIncreased(msg.sender, msg.value, block.timestamp);
  }

  /**
    Accept the auction results. Send the highest bid to the beneficiary and mint
    the winner an NFT item.
  */
  function accept() public nonReentrant onlyOwner {
    require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
    require(!ended, "The auction has already ended.");
    ended = true;

    // Take the highest bid (and any potential attacker dust) and mint the item.
    (bool success, ) = beneficiary.call{ value: address(this).balance }("");
    require(success, "The beneficiary is unable to receive the bid.");

    // Mint the item.
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

  /**
    Decline the auction results and return the highest bid.
  */
  function decline() public nonReentrant onlyOwner {
    require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
    require(!ended, "The auction has already ended.");
    ended = true;

    // Return the highest bidder their bid, plus any attacker dust.
    (bool bidderReturnSuccess, ) = payable(highestBidder).call{ value: address(this).balance }("");

    // If the highest bidder is unable to receive their bid, send it to the
    // auction beneficiary to rescue.
    if (!bidderReturnSuccess) {
      (bool beneficiaryRescueSuccess, ) = beneficiary.call{ value: address(this).balance }("");
      require(beneficiaryRescueSuccess, "The beneficiary is unable to rescue the bid.");
    }

    // The auction ended in failure.
    emit AuctionEnded(highestBidder, highestBid, block.timestamp, false);
  }

  /*
    The auction owner has not taken action to conclude the auction. After a set
    timeout period we allow anyone to conclude the auction.
  */
  function returnHighestBid() public nonReentrant {
    require(block.timestamp >= auctionEndTime.add(receiptBuffer), "Auction not yet expired.");
    require(!ended, "The auction has already ended.");
    ended = true;

    // Return the highest bidder their bid and any potential attacker dust.
    (bool bidderReturnSuccess, ) = payable(highestBidder).call{ value: address(this).balance }("");

    // If the highest bidder is unable to receive their bid, send it to the
    // auction beneficiary.
    if (!bidderReturnSuccess) {
      (bool beneficiaryRescueSuccess, ) = beneficiary.call{ value: address(this).balance }("");
      require(beneficiaryRescueSuccess, "The beneficiary is unable to rescue the bid.");
    }

    // The auction expired.
    emit AuctionExpired(highestBidder, highestBid, block.timestamp);
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
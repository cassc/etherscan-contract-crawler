// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {ICryptoPunksMarket} from "./interfaces/ICryptoPunksMarket.sol";

error InvalidOffer();
error InvalidBid();

/// @title The punk.bid v1 contract
/// @notice A permissionless and on-chain bid-side order book for CryptoPunks  
contract PunkBidMarketV1 is Owned {
  /// @notice The WETH contract
  address public immutable WETH;

  /// @notice The CryptoPunks Market contract
  address public immutable CRYPTOPUNKS_MARKET;

  /// @notice The protocol fee earned on every sale
  uint256 public constant FEE = 0.25 ether;

  struct Bid {
    address bidder;
    uint96 expiration;
    uint256 weiAmount;
    bytes32 itemsChecksum;
  }

  struct BidUpdate {
    uint256 bidId;
    uint256 weiAmount;
  }

  /// @notice A mapping pointing bid ids to bid structs
  mapping(uint256 => Bid) public bids;

  /// @notice The next bid id to be created
  uint256 public nextBidId = 1;

  /// @notice Emitted when a bid is entered
  event BidEntered(
    uint256 indexed bidId,
    address indexed bidder,
    uint256 weiAmount,
    uint96 expiration,
    bytes32 itemsChecksum,
    string name,
    bytes cartMetadata
  );

  /// @notice Emitted when a bid is updated
  event BidUpdated(uint256 indexed bidId, uint256 weiAmount);

  /// @notice Emitted when a bid is cancelled
  event BidCancelled(uint256 indexed bidId);

  /// @notice Emitted when a bid is filled
  event BidFilled(
    uint256 indexed bidId,
    uint256 punkIndex,
    address seller,
    address bidder,
    uint256 weiAmount
  );

  constructor(address _WETH, address _CRYPTOPUNKS_MARKET) Owned(msg.sender) {
    WETH = _WETH;
    CRYPTOPUNKS_MARKET = _CRYPTOPUNKS_MARKET;
  }

  receive() external payable {}

  /// @notice Enter a new bid
  /// @param weiAmount The amount to bid on
  /// @param expiration The expiration date
  /// @param itemsChecksum The root hash of a merkle tree where each leaf is a hashed punk id
  /// @param name the name of your bid
  /// @param cartMetadata The metadata needed to infer the punks included in your bid
  /// @dev for more info on the cartMetadata format, see https://github.com/punkbid/punkbid-js-sdk
  function enterBid(
    uint256 weiAmount,
    uint96 expiration,
    bytes32 itemsChecksum,
    string calldata name,
    bytes calldata cartMetadata
  ) external {
    bids[nextBidId] = Bid(msg.sender, expiration, weiAmount, itemsChecksum);
    emit BidEntered(
      nextBidId++,
      msg.sender,
      weiAmount,
      expiration,
      itemsChecksum,
      name,
      cartMetadata
    );
  }

  /// @notice Update the price of your bids
  /// @param updates The ids of the bids to update along with their new price
  function updateBids(BidUpdate[] calldata updates) external {
    uint256 len = updates.length;

    for (uint256 i = 0; i < len; ) {
      BidUpdate calldata update = updates[i];
      require(bids[update.bidId].bidder == msg.sender);
      bids[update.bidId].weiAmount = update.weiAmount;
      emit BidUpdated(update.bidId, update.weiAmount);

      unchecked {
        ++i;
      }
    }
  }

  /// @notice Cancel your bids
  /// @param bidIds The ids of the bids to cancel
  function cancelBids(uint256[] calldata bidIds) external {
    uint256 len = bidIds.length;

    for (uint256 i = 0; i < len; ) {
      uint256 bidId = bidIds[i];
      require(bids[bidId].bidder == msg.sender);
      delete bids[bidId];
      emit BidCancelled(bidId);

      unchecked {
        ++i;
      }
    }
  }

  /// @notice Accept a bid and sell your punk
  /// @param punkIndex The id of the punk to be sold
  /// @param minWeiAmount The minimum amount of sale
  /// @param bidId The id of the bid to be sold into
  /// @param proof The merkle proof to validate the bid includes the punk to be sold
  function acceptBid(
    uint256 punkIndex,
    uint256 minWeiAmount,
    uint256 bidId,
    bytes32[] calldata proof
  ) external {
    ICryptoPunksMarket.Offer memory offer = ICryptoPunksMarket(
      CRYPTOPUNKS_MARKET
    ).punksOfferedForSale(punkIndex);
    if (!offer.isForSale || msg.sender != offer.seller || offer.minValue > 0)
      revert InvalidOffer();

    Bid memory bid = bids[bidId];
    if (
      bid.weiAmount < minWeiAmount ||
      bid.expiration < uint96(block.timestamp) ||
      !MerkleProofLib.verify(
        proof,
        bid.itemsChecksum,
        keccak256(abi.encodePacked(punkIndex))
      )
    ) revert InvalidBid();

    IWETH9(WETH).transferFrom(bid.bidder, address(this), bid.weiAmount);
    IWETH9(WETH).withdraw(bid.weiAmount);
    ICryptoPunksMarket(CRYPTOPUNKS_MARKET).buyPunk(punkIndex);
    ICryptoPunksMarket(CRYPTOPUNKS_MARKET).transferPunk(bid.bidder, punkIndex);

    emit BidFilled(bidId, punkIndex, msg.sender, bid.bidder, bid.weiAmount);
    delete bids[bidId];

    (bool sent, ) = msg.sender.call{value: bid.weiAmount - FEE}(new bytes(0));
    require(sent);
  }

  function withdraw() external onlyOwner {
    (bool sent, ) = msg.sender.call{value: address(this).balance}(new bytes(0));
    require(sent);
  }
}
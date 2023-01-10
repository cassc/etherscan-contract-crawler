// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
interface IRedlionLegendaryGazette is IERC721Upgradeable {
  /**
   * Event emitted when a new auction is launched
   * @param issueId ID of the new auction
   * @param startTime Timestamp of when the auction starts
   */
  event AuctionLaunched(uint indexed issueId, uint startTime);

  /**
   * Event emitted when a new bid is placed
   * @param issueId ID of the auction the bid was placed in
   * @param bidder Address of the bidder
   * @param price Value of the bid
   */
  event AuctionBid(uint indexed issueId, address indexed bidder, uint price, uint totalBid);

  /**
   * Event emitted when an auction ends
   * @param issueId ID of the auction that ended
   * @param winner Address of the winning bidder
   * @param winningBid Data for the winning bid
   */
  event AuctionEnded(uint indexed issueId, address indexed winner, Bid winningBid);

  struct Bid {
    uint value;
    uint time;
    address bidder;
    uint fee;
  }
  struct BidderIndex {
    uint index;
    bool set;
  }
  struct Issue {
    uint issueNumber;
    uint256 reservePrice;
    string uri;
    Bid[] bids;
    Bid[] bidHistory;
    uint startTime;
    uint endTime;
    bool refunded;
  }

  function claim(uint _issue) external;

  function launchAuction(
    uint256 _issue,
    uint256 _reserve,
    string memory _uri
  ) external;

  function isAuctionLaunched(uint256 _issue) external view returns (bool);
}
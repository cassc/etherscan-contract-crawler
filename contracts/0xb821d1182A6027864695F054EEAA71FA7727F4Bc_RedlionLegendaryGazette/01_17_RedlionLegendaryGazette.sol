// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../libraries/interfaces/IRedlionLegendaryGazette.sol';
import '../libraries/interfaces/IRedlionGazetteManager.sol';

/**
 * @title Redlion Legendary Gazette
 * @author Gui "Qruz" Rodrigues (@0xqruz)
 * @dev This contract allows the creation and management of auctions for rare issues of Redlion Legendary Gazette. Bidders can place bids on auctions and the contract will automatically keep track of the current highest bid. The owner of the contract can force end an auction and the winning bidder will be awarded the NFT.
 * @notice This contract is made for Redlion (https://redlion.red)
 */
contract RedlionLegendaryGazette is
  Initializable,
  IRedlionLegendaryGazette,
  ERC721Upgradeable,
  AccessControlUpgradeable
{
  /*///////////////////////////////////////////////////////////////
                         VARIABLES
  ///////////////////////////////////////////////////////////////*/

  uint256 public MINIMUM_OUTBID; // 1000 => 10.00%
  uint256 public MAX_AUCTION_TIME; // seconds
  uint256 public MIN_AUCTION_TIME; // seconds
  uint256 public ENTRY_FEE;

  mapping(uint256 => mapping(address => BidderIndex)) biddersIndex;

  bytes32 public MANAGER_ROLE;
  bytes32 public OWNER_ROLE;

  address CURRENT_MANAGER;

  mapping(uint256 => Issue) public issues;

  uint256 ONGOING;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Initializes the contract with a given manager address.
   * @param _manager The address of the contract manager.
   */
  function initialize(address _manager) public initializer {
    MANAGER_ROLE = keccak256('MANAGER');
    OWNER_ROLE = keccak256('OWNER');
    MINIMUM_OUTBID = 1000; // 1000 => 10.00%
    MAX_AUCTION_TIME = 86400; // seconds
    MIN_AUCTION_TIME = 300; // seconds
    ENTRY_FEE = 0 ether;
    ONGOING = 0;
    __ERC721_init('Redlion Legendary Gazette', 'RLLEGENDARY');
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(OWNER_ROLE, msg.sender);
    _setManager(_manager);
  }

  /**
   * Launches a new auction for the given issue with the given reserver proce and metadata uri
   * @param _issue ID of the issue being auctioned
   * @param _reserve The reserve price of the auction
   * @param _uri URI for the issue
   */
  function launchAuction(
    uint256 _issue,
    uint256 _reserve,
    string memory _uri
  ) public override(IRedlionLegendaryGazette) onlyRole(MANAGER_ROLE) {
    require(!isAuctionLaunched(_issue), 'ALREADY_EXISTENT_AUCTION');

    uint256 startTime = block.timestamp;

    Issue storage issue = issues[_issue];
    issue.issueNumber = _issue;
    issue.startTime = startTime;
    issue.reservePrice = _reserve;
    issue.uri = _uri;

    emit AuctionLaunched(_issue, startTime);
  }

  /**
   * Places a bid on the given auction.
   * @param _issue ID of the auction to bid on.
   * @custom:thorws BELOW_RESERVE_PRICE if price is below the reserve price
   * @custom:thorws CANNOT_OUTBID if price is below the outbid minimum
   * @custom:emits AuctionBid
   */
  function placeBid(uint256 _issue) external payable {
    _requireAuctionNotEnded(_issue);
    uint256 time = block.timestamp;

    Issue storage issue = issues[_issue];

    uint256 currentBidValue = _currentBidValue(_issue, msg.sender);
    uint256 calculatedBidValue = currentBidValue + msg.value;
    if (!biddersIndex[_issue][msg.sender].set) {
      /**
       * We take an entry fee that will be fully refunded at the end of the auction. All losers will be refunded
       * in any case, we'll keep the winners fee in case we have to force claim. This can be set to 0 to be disabled
       */
      calculatedBidValue -= ENTRY_FEE;
    }

    require(calculatedBidValue >= issue.reservePrice, 'BELOW_RESERVE_PRICE');

    require(calculatedBidValue >= (minimumOutbid(_issue)), 'CANNOT_OUTBID');

    Bid memory bid = Bid({
      value: calculatedBidValue,
      time: time,
      bidder: msg.sender,
      fee: ENTRY_FEE
    });

    if (issue.bids.length == 0) {
      ONGOING++;
    }

    if (!biddersIndex[_issue][msg.sender].set) {
      uint256 newIndex = issue.bids.length;
      biddersIndex[_issue][msg.sender].index = newIndex;
      biddersIndex[_issue][msg.sender].set = true;
      issue.bids.push(bid);
    } else {
      uint256 bIndex = biddersIndex[_issue][msg.sender].index;
      issue.bids[bIndex].value = bid.value;
      issue.bids[bIndex].time = bid.time;
    }

    issue.bidHistory.push(bid);
    uint256 timeLimit = MAX_AUCTION_TIME / (2 ** (issue.bids.length - 1));
    if (timeLimit < MIN_AUCTION_TIME) timeLimit = MIN_AUCTION_TIME;
    issue.endTime = time + timeLimit;

    // Emit an event to announce the new bid
    emit AuctionBid(_issue, msg.sender, msg.value, calculatedBidValue);
  }

  // Returns information about the given issue
  function getIssue(uint256 _issue) public view returns (Issue memory) {
    Issue storage issue = issues[_issue];
    return issue;
  }

  /*///////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721Upgradeable) returns (string memory) {
    _requireAuctionExists(tokenId);
    return issues[tokenId].uri;
  }

  function liveAuctions() public view returns (uint) {
    return ONGOING;
  }

  /**
   * Claim the Legendary Gazette and receive an extra normal gazette
   * @dev Only the winner can call this function otherwise it throws CALLER_NOT_WINNER
   * @param _issue The auction number to claim
   */
  function claim(uint256 _issue) public override(IRedlionLegendaryGazette) {
    _requireWinningBidder(_issue, msg.sender);
    _claim(_issue, true);
  }

  /**
   * @dev Returns the current highest bid on the given auction.
   * @param _issue The auction number
   */
  function winningBid(uint256 _issue) public view returns (Bid memory) {
    uint256 winningValue = 0;
    uint256 index = 0;
    Issue storage issue = issues[_issue];
    if (issue.bids.length == 0) return Bid(0, 0, address(0), 0);
    for (uint256 i = 0; i < issue.bids.length; i++) {
      Bid memory _bid = issue.bids[i];
      if (_bid.value > winningValue) {
        index = i;
        winningValue = _bid.value;
      }
    }
    return issue.bids[index];
  }

  /**
   * Returns wether the auction was launched or not
   * @return true if startTime is not equals to `0`, false by default
   */
  function isAuctionLaunched(
    uint256 _issue
  ) public view override(IRedlionLegendaryGazette) returns (bool) {
    return getIssue(_issue).startTime != 0;
  }

  /**
   * Returns the minimum value to outbid the requested issue
   * @return value representing the minimum value (wei) to bid
   */
  function minimumOutbid(uint256 _issue) public view returns (uint) {
    _requireAuctionExists(_issue);
    return
      winningBid(_issue).value +
      ((winningBid(_issue).value / 10000) * MINIMUM_OUTBID);
  }

  /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  /**
   * Sets the new gazette manager contract
   * @dev There can only be only one manager contract to avoid obsolete permissions. Limited to OWNER
   * @param _manager The subscription manager contract address
   */
  function setManager(address _manager) external onlyRole(OWNER_ROLE) {
    _setManager(_manager);
  }

  /**
   * Force claims the selected issue
   * @dev This is only used when the winner did not claim his Legendary Gazette. Doing so locks users funds, no good!
   * @param _issue The auction number
   */
  function forceClaim(uint256 _issue) external onlyRole(OWNER_ROLE) {
    _claim(_issue, false);
  }

  /**
   * @dev Sets the options for the auctions.
   * @param _min The minimum auction time in seconds.
   * @param _max The maximum auction time in seconds.
   * @param _outbid The minimum percentage increase required to outbid the current highest bid.
   * @param _fee The entry fee for participating in auctions, which will be refunded to losing bidders.
   */
  function setAuctionOptions(
    uint256 _min,
    uint256 _max,
    uint256 _outbid,
    uint256 _fee
  ) external onlyRole(OWNER_ROLE) {
    require(_min < _max, 'INVALID_TIME_LIMIT');
    MIN_AUCTION_TIME = _min;
    MAX_AUCTION_TIME = _max;
    MINIMUM_OUTBID = _outbid;
    ENTRY_FEE = _fee;
  }

  /**
   * @dev Sets the new uri for selected issue.
   * @param _issue Issue ID
   * @param _uri Metadata uri
   */
  function setTokenURI(
    uint256 _issue,
    string calldata _uri
  ) external onlyRole(OWNER_ROLE) {
    _requireAuctionExists(_issue);
    issues[_issue].uri = _uri;
  }

  /**
   * @notice Withdraws the contract balance
   * @dev Only the owner can withdraw the contract balance
   */
  function withdraw() external onlyRole(OWNER_ROLE) {
    require(ONGOING == 0, 'AUCTION_ONGOING');
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /*///////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  /**
   * Returns the current gazette manager contract
   * @return The address of the current gazette manager contract
   */
  function getManager() internal view returns (IRedlionGazetteManager) {
    return IRedlionGazetteManager(CURRENT_MANAGER);
  }

  function _claim(uint256 _issue, bool _fee) internal {
    _requireAuctionEnded(_issue);
    require(ONGOING > 0, 'NO_LIVE_AUCTIONS');
    ONGOING--;
    Bid memory wBid = winningBid(_issue);
    _refund(_issue, _fee);
    _mint(wBid.bidder, _issue);
    IRedlionGazette RLG = getManager().getRLG();
    RLG.mint(wBid.bidder, _issue, 1, true);
    emit AuctionEnded(_issue, wBid.bidder, wBid);
  }

  /**
   * Refunds the entry fee to the given bidder.
   * @param _issue ID of the auction the bidder participated in.
   * @param _fee Whether to refund the winning bidder's entry fee.
   */
  function _refund(uint256 _issue, bool _fee) internal {
    _requireAuctionEnded(_issue);
    // Get the issue data
    Issue storage issue = issues[_issue];

    require(!issue.refunded, 'ALREADY_REFUNDED');
    // Get the winning bid
    Bid memory wBid = winningBid(_issue);

    issue.refunded = true;

    // The addresses should appear only once in the issue.bidders array
    for (uint256 i = 0; i < issue.bids.length; i++) {
      Bid memory bid = issue.bids[i];
      if (bid.bidder != wBid.bidder) {
        payable(bid.bidder).transfer(issue.bids[i].value + issue.bids[i].fee);
      }
    }
    if (_fee) {
      // Refund entry fee
      payable(wBid.bidder).transfer(wBid.fee);
    }
  }

  /**
   * @dev Returns the latest bid value made by the given bidder on the given auction.
   * @param _issue ID of the auction to get the bid value for.
   * @param _address Address of the bidder to get the bid value for.
   * @return The latest bid value made by the bidder.
   */
  function _currentBidValue(
    uint256 _issue,
    address _address
  ) internal view returns (uint256) {
    uint256 latestTime = 0;
    uint256 latestValue = 0;
    Issue storage issue = issues[_issue];
    for (uint256 i = 0; i < issue.bids.length; i++) {
      Bid memory _bid = issue.bids[i];
      if (_bid.bidder == _address && _bid.time > latestTime) {
        latestTime = _bid.time;
        latestValue = _bid.value;
      }
    }
    return latestValue;
  }

  function _requireAuctionExists(uint256 _issue) internal view {
    require(isAuctionLaunched(_issue), 'NONEXISTENT_AUCTION');
  }

  function _requireAuctionNotEnded(uint256 _issue) internal view {
    _requireAuctionExists(_issue);
    require(
      issues[_issue].endTime == 0 || issues[_issue].endTime > block.timestamp,
      'AUCTION_ALREADY_ENDED'
    );
  }

  function _requireAuctionEnded(uint256 _issue) internal view {
    _requireAuctionExists(_issue);
    require(issues[_issue].endTime < block.timestamp, 'AUCTION_NOT_ENDED');
  }

  function _setManager(address _manager) internal {
    if (CURRENT_MANAGER != address(0)) {
      _revokeRole(MANAGER_ROLE, CURRENT_MANAGER);
    }
    _grantRole(MANAGER_ROLE, _manager);
    CURRENT_MANAGER = _manager;
  }

  /**
   * This internal function checks if the given address is the winning bidder for the given auction.
   * @param _issue ID of the auction
   * @param _bidder Address to check
   */
  function _requireWinningBidder(
    uint256 _issue,
    address _bidder
  ) internal view {
    Issue memory issue = issues[_issue];
    require(issue.bids.length > 0, 'NO_BIDS');
    Bid memory wBid = winningBid(_issue);
    require(wBid.bidder == _bidder, 'CALLER_NOT_WINNER');
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721Upgradeable, AccessControlUpgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
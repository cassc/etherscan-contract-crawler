// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract TBOTFightClubAuction is Ownable, Pausable, ReentrancyGuard {
  event Bid(address indexed account, uint256 amount);

  /// @dev Compiler will pack this into a single 256bit word.
  struct BidderInfo {
    // bidValue . max bidValue is 2^224 (2.69e49) ether is enough for reality
    uint224 bidValue;
    // index of bidder in _bidderArr . 4e9 bidder is enough for reality
    uint32 bidderArrIndex;
  }

  string public constant VERSION = "1.0.1-t";

  uint256 public startPrice;

  uint64 public decimals;

  address payable public tkxWallet;

  /// @notice startAuctionTime unit second
  /// @return startAuctionTime unit second
  uint64 public startAuctionTime;
  /// @notice endAuctionTime unit second
  /// @return endAuctionTime unit second
  uint64 public endAuctionTime;

  mapping(address => BidderInfo) private _bidByAddressMapping;

  /// @notice max length allow is 2^32 (4e9). coz we process index as uint32
  address[] private _bidderArr;

  /// @notice 2^32 (4e9) bidder is enough for reality .
  ///         value type(uint32).max as empty slot (because index value start from 0)
  uint32[4] private _topBidderIndexArr;

  /// @notice constructor
  /// @dev Explain to a developer any extra details
  /// @param startPrice_ : start price for auction
  /// @param decimals_ : decimals allow for bid value
  /// @param tkxWallet_ : wallet that will be receiver every bid amount
  /// @param startAuctionTime_  : time to start auction
  /// @param endAuctionTime_ : time to end auction
  constructor(
    uint256 startPrice_,
    uint64 decimals_,
    address payable tkxWallet_,
    uint64 startAuctionTime_,
    uint64 endAuctionTime_
  ) {
    require(tkxWallet_ != address(0));

    startPrice = startPrice_;
    decimals = decimals_;
    tkxWallet = tkxWallet_;
    startAuctionTime = startAuctionTime_;
    endAuctionTime = endAuctionTime_;
    // init _topBidderIndexArr
    _topBidderIndexArr[0] = type(uint32).max;
    _topBidderIndexArr[1] = type(uint32).max;
    _topBidderIndexArr[2] = type(uint32).max;
    _topBidderIndexArr[3] = type(uint32).max;
  }

  modifier whenAuctionActive() {
    require(block.timestamp >= startAuctionTime && block.timestamp <= endAuctionTime, "Auction is not active");
    _;
  }

  /************************
   * @dev for pause
   */

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /********************
   *
   */

  function setTime(uint64 startAuctionTime_, uint64 endAuctionTime_) external onlyOwner {
    startAuctionTime = startAuctionTime_;
    endAuctionTime = endAuctionTime_;
  }

  function setStartPrice(uint256 startPrice_, uint64 decimals_) external onlyOwner {
    startPrice = startPrice_;
    decimals = decimals_;
  }

  function setTkxWallet(address payable tkxWallet_) external onlyOwner {
    tkxWallet = tkxWallet_;
  }

  /***********************
   * @dev for bid function
   */

  /// @notice Get bidValue of bidder address
  /// @param bidder : bidder address
  /// @return bidValue : bidValue of bidder
  function getBidOfAddress(address bidder) external view returns (uint256) {
    return _bidByAddressMapping[bidder].bidValue;
  }

  /// @notice Use to get all top 4 bidder belong with bidValue
  /// @return bidderArr : array of bidder address
  /// @return bidValueArr : array of bidValue belong with bidderArr
  function getTopBidder() external view returns (address[4] memory bidderArr, uint256[4] memory bidValueArr) {
    for (uint256 index = 0; index < _topBidderIndexArr.length; index++) {
      if (_topBidderIndexArr[index] == type(uint32).max) {
        bidderArr[index] = address(0);
        bidValueArr[index] = 0;
      } else {
        bidderArr[index] = _bidderArr[_topBidderIndexArr[index]];
        bidValueArr[index] = _bidByAddressMapping[bidderArr[index]].bidValue;
      }
    }
  }

  /// @notice Use to get all bidder and bidValue
  /// @param skip : skip number of bidder
  /// @param limit : limit number of bidder return
  /// @return bidderArr : array of bidder address
  /// @return bidValueArr : array of bidValue belong with bidderArr
  function getBidders(uint32 skip, uint32 limit) external view returns (address[] memory, uint256[] memory) {
    uint256 endIndex = _bidderArr.length;
    if (limit > 0 && (skip + limit) < endIndex) {
      endIndex = skip + limit;
    }

    address[] memory bidderArr = new address[](endIndex - skip);
    uint256[] memory bidValueArr = new uint256[](endIndex - skip);

    for (uint256 index = skip; index < endIndex; index++) {
      bidderArr[index - skip] = _bidderArr[index];
      bidValueArr[index - skip] = _bidByAddressMapping[_bidderArr[index]].bidValue;
    }

    return (bidderArr, bidValueArr);
  }

  /// @notice getTotalBidder
  /// @return totalBidder total bidder
  function getTotalBidder() external view returns (uint256 totalBidder) {
    return _bidderArr.length;
  }

  /// @notice
  /// @dev
  function bid() external payable nonReentrant whenNotPaused whenAuctionActive {
    if (_bidByAddressMapping[msg.sender].bidValue == 0) {
      require(msg.value >= startPrice, "Your bid must be equal to or higher than the Starting Bid Price");
    }
    require((msg.value % (10**(18 - decimals))) == 0, "Not correct decimals");
    require(msg.value <= type(uint224).max, "You bid too much money");
    require(_bidderArr.length < type(uint32).max, "Can not bid anymore");

    //
    // update bid info
    //
    if (_bidByAddressMapping[msg.sender].bidValue == 0) {
      _bidByAddressMapping[msg.sender].bidderArrIndex = uint32(_bidderArr.length);
      _bidderArr.push(msg.sender);
    }

    // overflow bidValue 2^224 is not reality
    _bidByAddressMapping[msg.sender].bidValue += uint224(msg.value);

    //
    // process top bid
    //

    uint32 currentBidderIndex = _bidByAddressMapping[msg.sender].bidderArrIndex;
    uint224 currentBidValue = _bidByAddressMapping[msg.sender].bidValue;
    // this flag use to indicate when process reorder other top bidder after insert new bid
    // use to keep sooner bidder stay on high rank when reorder top bidder (for bidder those have same bid value)
    bool isReorderTopBidder = false;

    for (uint256 index = 0; index < _topBidderIndexArr.length; index++) {
      uint32 currentTopIndex = _topBidderIndexArr[index];
      if (currentTopIndex == type(uint32).max) {
        // empty slot => record current bidder is top and break
        _topBidderIndexArr[index] = currentBidderIndex;
        break;
      }

      // this flag use to keep sooner bidder stay on high rank when reorder top bidder
      // take place even when bidValue is equal (except new bid)
      bool shouldTakeLocation = isReorderTopBidder &&
        currentBidValue == _bidByAddressMapping[_bidderArr[currentTopIndex]].bidValue;

      if (
        (currentBidValue > _bidByAddressMapping[_bidderArr[currentTopIndex]].bidValue || shouldTakeLocation) &&
        _topBidderIndexArr[index] != currentBidderIndex
      ) {
        // current bidder lagger than current top => insert current bidder in here and shift right other top bidder
        uint32 tmpIndex = _topBidderIndexArr[index];
        _topBidderIndexArr[index] = currentBidderIndex;

        // clear current position in _topBidderIndexArr of currentBidderIndex
        for (
          uint256 indexClearDuplicated = index + 1;
          indexClearDuplicated < _topBidderIndexArr.length;
          indexClearDuplicated++
        ) {
          if (currentBidderIndex == _topBidderIndexArr[indexClearDuplicated]) {
            _topBidderIndexArr[indexClearDuplicated] = type(uint32).max;
            break;
          }
        }

        isReorderTopBidder = true;
        currentBidderIndex = tmpIndex;
        currentBidValue = _bidByAddressMapping[_bidderArr[currentBidderIndex]].bidValue;
      } else if (_topBidderIndexArr[index] == currentBidderIndex) {
        // if currentBidder is existed in top list at correct position => break;
        break;
      }
    }

    emit Bid(msg.sender, _bidByAddressMapping[msg.sender].bidValue);

    // transfer balance to tkxWallet
    payable(tkxWallet).transfer(msg.value);
  }
}
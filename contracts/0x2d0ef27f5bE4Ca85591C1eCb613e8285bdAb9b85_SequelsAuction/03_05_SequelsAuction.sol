// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship
// contract by steviep.eth

/*

███████ ███████  ██████  ██    ██ ███████ ██      ███████
██      ██      ██    ██ ██    ██ ██      ██      ██
███████ █████   ██    ██ ██    ██ █████   ██      ███████
     ██ ██      ██ ▄▄ ██ ██    ██ ██      ██           ██
███████ ███████  ██████   ██████  ███████ ███████ ███████
                    ▀▀

 █████  ██    ██  ██████ ████████ ██  ██████  ███    ██
██   ██ ██    ██ ██         ██    ██ ██    ██ ████   ██
███████ ██    ██ ██         ██    ██ ██    ██ ██ ██  ██
██   ██ ██    ██ ██         ██    ██ ██    ██ ██  ██ ██
██   ██  ██████   ██████    ██    ██  ██████  ██   ████

*/

import "./SequelsBase.sol";

pragma solidity ^0.8.17;

interface FPP {
  function logPassUse(uint256 tokenId, uint256 projectId) external;
  function ownerOf(uint256 tokenId) external returns (address);
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint256 wad) external;
  function transfer(address to, uint256 value) external returns (bool);
}

contract SequelsAuction {
  uint256 public immutable PROJECT_START_TIME;
  uint256 public immutable PROJECT_END_TIME;
  address public immutable weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public fpp = 0xA8A425864dB32fCBB459Bf527BdBb8128e6abF21;
  uint256 public fppProjectId = 2;
  address public beneficiary1;
  address public beneficiary2;

  uint256 public bidIncreaseBps = 1000;
  uint256 public mintPassRebateBps = 1000;
  uint256 public minBid = 0.01 ether;
  bool public paused;

  event BidMade(uint256 indexed day, address bidder, uint256 amount, uint256 timestamp);
  event Settled(uint256 indexed day, uint256 timestamp);

  struct Bid {
    uint128 amount;
    uint128 timestamp;
    address bidder;
    bool usesMintPass;
    uint256 mintPassId;
  }

  mapping(uint256 => Bid) public auctions;
  mapping(uint256 => bool) public auctionSettlements;

  SequelsBase public sequelsBase;

  constructor(SequelsBase _sequelsBase, uint256 startTime, uint256 endTime) {
    sequelsBase = _sequelsBase;
    beneficiary1 = msg.sender;
    beneficiary2 = msg.sender;
    PROJECT_START_TIME = startTime;
    PROJECT_END_TIME = endTime;
  }

  function bid(uint256 day) external payable {
    bid(day, false, 0);
  }

  function bidWithMintPass(uint256 day, uint256 mintPassId) external payable {
    require(FPP(fpp).ownerOf(mintPassId) == msg.sender, 'Caller is not the owner of FPP');
    bid(day, true, mintPassId);
  }

  function bid(uint256 day, bool usesMintPass, uint256 mintPassId) private {
    require(isAuctionActive(day), 'Auction for this day is not active');
    require(!paused, 'Bidding is paused');

    Bid storage highestBid = auctions[day];

    require(
      msg.value >= (highestBid.amount * (10000 + bidIncreaseBps) / 10000)
      && msg.value >= minBid,
      'Bid not high enough'
    );

    uint256 refundAmount;
    address refundBidder;

    if (highestBid.timestamp > 0) {
      refundAmount = highestBid.amount;
      refundBidder = highestBid.bidder;
    }

    highestBid.timestamp = uint128(block.timestamp);
    highestBid.amount = uint128(msg.value);
    highestBid.bidder = msg.sender;
    highestBid.usesMintPass = usesMintPass;
    highestBid.mintPassId = mintPassId;

    emit BidMade(day, msg.sender, msg.value, block.timestamp);

    if (refundAmount > 0) _safeTransferETH(refundBidder, refundAmount);
  }

  function settleAuction(uint256 day) external payable {
    require(!auctionSettlements[day], 'Auction has already been settled');
    require(currentDay() >= day, 'Auction for this day has not started');
    require(!isAuctionActive(day), 'Auction for this day is still active');

    Bid storage highestBid = auctions[day];

    auctionSettlements[day] = true;

    uint256 amountToPay = highestBid.amount;

    if (highestBid.timestamp > 0) {
      sequelsBase.mint(highestBid.bidder, day);

    } else {
      require(msg.sender == owner(), 'Ownable: caller is not the owner');
      require(msg.value >= minBid, 'Bid not high enough');
      amountToPay = msg.value;

      sequelsBase.mint(msg.sender, day);
    }

    emit Settled(day, block.timestamp);

    bool mintPassStillOwned = FPP(fpp).ownerOf(highestBid.mintPassId) == highestBid.bidder;

    uint256 totalRebate = 0;
    if (highestBid.usesMintPass && mintPassStillOwned) {
      FPP(fpp).logPassUse(highestBid.mintPassId, fppProjectId);
      totalRebate = amountToPay * (mintPassRebateBps) / 10000;
    }

    if (totalRebate > 0) {
      _safeTransferETH(highestBid.bidder, totalRebate);
      payable(beneficiary2).transfer(amountToPay - totalRebate);
    } else {
      payable(beneficiary1).transfer(amountToPay);
    }
  }

  function owner() public view returns (address) {
    return sequelsBase.owner();
  }

  modifier onlyOwner {
    require(msg.sender == owner(), 'Ownable: caller is not the owner');
    _;
  }

  function setBidIncreaseBps(uint256 _bidIncreaseBps) external onlyOwner {
    bidIncreaseBps = _bidIncreaseBps;
  }

  function setMintPassRebateBps(uint256 _mintPassRebateBps) external onlyOwner {
    mintPassRebateBps = _mintPassRebateBps;
  }

  function setMinBid(uint256 _minBid) external onlyOwner {
    minBid = _minBid;
  }

  function setBeneficiary(address _beneficiary1, address _beneficiary2) external onlyOwner {
    beneficiary1 = _beneficiary1;
    beneficiary2 = _beneficiary2;
  }

  function setFpp(address _fpp, uint256 _fppProjectId) external onlyOwner {
    fpp = _fpp;
    fppProjectId = _fppProjectId;
  }

  function setPaused(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function isAuctionActive(uint256 day) public view returns (bool) {
    uint256 startTime = (day * 1 days) + PROJECT_START_TIME;
    uint256 endTime = startTime + 1 days;

    return (
      block.timestamp >= startTime
      && (
        block.timestamp < endTime
        || block.timestamp < auctions[day].timestamp + 10 minutes
      )
    );
  }

  function currentDay() public view returns (uint256) {
    if (block.timestamp < PROJECT_START_TIME) {
      return 0;

    } else if (block.timestamp > PROJECT_END_TIME) {
      return (PROJECT_END_TIME - PROJECT_START_TIME) / 1 days;

    } else {
      return (block.timestamp - PROJECT_START_TIME) / 1 days;
    }
  }

  /**
   * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
   */
  function _safeTransferETHWithFallback(address to, uint256 amount) internal {
    if (!_safeTransferETH(to, amount)) {
      IWETH(weth).deposit{ value: amount }();
      IWETH(weth).transfer(to, amount);
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
}

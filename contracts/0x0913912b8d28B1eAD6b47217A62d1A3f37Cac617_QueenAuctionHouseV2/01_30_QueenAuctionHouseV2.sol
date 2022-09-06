// SPDX-License-Identifier: MIT

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RoyalLibrary} from "./lib/RoyalLibrary.sol";
import {IQueenAuctionHouse} from "../interfaces/IQueenAuctionHouse.sol";
import {IQueenPalace} from "../interfaces/IQueenPalace.sol";
import {BaseContractControllerUpgradeable} from "./base/BaseContractControllerUpgradeable.sol";
import {IWETH} from "../interfaces/IWETH.sol";

contract QueenAuctionHouseV2 is
  IQueenAuctionHouse,
  BaseContractControllerUpgradeable
{
  using Address for address;

  string public constant implementationVersion = "0.20";
  // The minimum bid % raise over last successfull bid
  uint8 public bidRaiseRate;
  //minimum bid increment by queene rarity traits
  uint256[] rarityBidRaiseMap; //(rarityId-1 => %)
  // The minimum amount of time left in an auction after a new bid is created
  uint256 public timeTolerance;
  // The initial minimun bid of the auction
  uint256 public initialBid;
  //fallback funds
  uint256 public fallbackDaoFunds;
  // The duration of a single auction
  uint256 public duration;
  // The address of the WETH contract
  address public weth;
  // current auction
  RoyalLibrary.sAUCTION public currentAuction;

  /**
   * @notice Initialize the auction house and base contracts,
   * populate configuration values, and pause the contract.
   * @dev This function can only be called once.
   */
  function initialize(
    IQueenPalace _queenPalace,
    address _weth,
    uint256 _timeTolerance,
    uint256 _initialBid,
    uint8 _bidRaiseRate,
    uint256 _duration
  ) external initializer {
    if (!initialized) {
      __Pausable_init();
      __ReentrancyGuard_init();
      __Ownable_init();

      _registerInterface(type(IQueenAuctionHouse).interfaceId);

      _pause();

      queenPalace = _queenPalace;
      weth = _weth;

      timeTolerance = _timeTolerance;
      initialBid = _initialBid;
      bidRaiseRate = _bidRaiseRate;
      duration = _duration;

      rarityBidRaiseMap.push(0); //increment for rarityId 1
      rarityBidRaiseMap.push(5); //increment for rarityId 2
      rarityBidRaiseMap.push(10); //increment for rarityId 3

      initialized = true;
    }
  }

  function setWeth(address _weth)
    external
    onlyOwnerOrChiefDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    weth = _weth;
  }

  /**
   * @notice End the current auction, send value to contracts and QueenE to Winner.
   */
  function endAuction() external override nonReentrant {
    _endAuction();
  }

  /**
   * @notice End the current auction, send value to contracts and QueenE to Winner.
   */
  function settleAuction() external nonReentrant whenNotPaused {
    if (!currentAuction.ended) _endAuction();
    if (currentAuction.ended) _startAuction();
  }

  /**
   * @notice try to make bid for QueenE with giver value (WEI).
   * @dev This contract only accepts payment in ETH.
   */
  function bid(uint256 queeneId) external payable override {
    RoyalLibrary.sAUCTION memory _currentAuction = currentAuction;

    require(!_currentAuction.ended, "Current Auction Ended");
    require(_currentAuction.queeneId == queeneId, "QueenE is not for auction");
    require(
      block.timestamp < _currentAuction.auctionEndTime,
      "Auction expired"
    );

    require(
      msg.value >= _currentAuction.initialBidPrice,
      string(
        abi.encodePacked(
          "Must send at least initial Bid value ",
          Strings.toString(_currentAuction.initialBidPrice)
        )
      )
    );
    require(
      msg.value >=
        _currentAuction.lastBidAmount +
          ((_currentAuction.lastBidAmount * bidRaiseRate) / 100),
      "Bid must be at least bidRaiseRate percentage above last bid!"
      //string(abi.encodePacked('Bid must be at least ', Strings.toString(bidRaiseRate), ' above last bid!'))
    );
    require(
      queenPalace.isWhiteListed(msg.sender),
      "Address not allowed to bid"
    );

    address payable lastBidder = _currentAuction.bidder;

    // Refund the last bidder, if applicable
    if (lastBidder != address(0)) {
      _safeTransferETHWithFallback(lastBidder, _currentAuction.lastBidAmount);
    }

    currentAuction.lastBidAmount = msg.value;
    currentAuction.bidder = payable(msg.sender);

    // Extend the auction if the bid was received within `timeTolerance` of the auction end time
    bool extended = _currentAuction.auctionEndTime - block.timestamp <
      timeTolerance;
    if (extended) {
      currentAuction.auctionEndTime = currentAuction.auctionEndTime =
        block.timestamp +
        timeTolerance;
    }

    emit AuctionBid(currentAuction.queeneId, msg.sender, msg.value, extended);

    if (extended) {
      emit AuctionExtended(
        currentAuction.queeneId,
        currentAuction.auctionEndTime
      );
    }
  }

  /**
   * @notice Pause the Queens auction house.
   */
  function pause()
    external
    override(BaseContractControllerUpgradeable, IQueenAuctionHouse)
    onlyOwnerOrDeveloper
  {
    _pause();
  }

  /**
   * @notice Unpause the Queens auction house.
   */
  function unpause()
    external
    override(BaseContractControllerUpgradeable, IQueenAuctionHouse)
    onlyOwnerOrDeveloper
  {
    require(
      !queenPalace.isOnImplementation(),
      "Can't Unpause while implementing"
    );

    _unpause();

    if (currentAuction.auctionStartTime == 0 || currentAuction.ended) {
      _startAuction();
    }
  }

  /**
   * @notice Set the auction time tolerance for bid.
   * @dev Only callable by the owner.
   */
  function setTimeTolerance(uint256 _timeTolerance)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    timeTolerance = _timeTolerance;

    emit AuctionTimeToleranceUpdated(_timeTolerance);
  }

  /**
   * @notice Set the auction initial bid price.
   * @dev Only callable by the owner.
   */
  function setInitialBid(uint256 _initialBid)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    initialBid = _initialBid;

    emit AuctionInitialBidUpdated(_initialBid);
  }

  /**
   * @notice Set the auction next bid increment percentage.
   * @dev Only callable by the owner.
   */
  function setBidRaiseRate(uint8 _bidRaiseRate)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    bidRaiseRate = _bidRaiseRate;

    emit AuctionInitialBidUpdated(bidRaiseRate);
  }

  /**
   * @notice Set the auction duration time.
   * @dev Only callable by the owner.
   */
  function setDuration(uint256 _duration)
    external
    override
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    duration = _duration;

    emit AuctionDurationUpdated(duration);
  }

  /**
   * @notice Start an new auction.
   */
  function _startAuction() internal {
    require(
      !queenPalace.isOnImplementation(),
      "Can't Start while implementing"
    );

    try queenPalace.QueenE().mint() returns (uint256 queeneId) {
      uint256 startTime = block.timestamp;
      //starts with 4h duration and scalates 1 hour till max duration
      uint256 endTime = startTime +
        LowerNumber(duration, (10800 + (queeneId * 3600)));

      uint256 rarityIncrement = queenPalace
        .QueenLab()
        .getQueenRarityBidIncrement(
          queenPalace.QueenE().getQueenE(queeneId).dna,
          rarityBidRaiseMap
        );

      currentAuction = RoyalLibrary.sAUCTION({
        queeneId: queeneId,
        lastBidAmount: 0,
        auctionStartTime: startTime,
        auctionEndTime: endTime,
        initialBidPrice: initialBid +
          (SafeMath.div(initialBid, 100) * rarityIncrement),
        bidder: payable(0),
        ended: false
      });

      emit AuctionStarted(
        queeneId,
        startTime,
        endTime,
        initialBid + (SafeMath.div(initialBid, 100) * rarityIncrement)
      );
    } catch Error(string memory err) {
      _pause();
      revert(err);
    }
  }

  /**
   * @notice Settle an auction, finalizing the bid and paying out to the owner.
   * @dev If there are no bids, the Noun is burned.
   */
  function _endAuction() internal {
    RoyalLibrary.sAUCTION memory _currentAuction = currentAuction;

    require(_currentAuction.auctionStartTime != 0, "Auction hasn't begun");
    require(!_currentAuction.ended, "Auction has already ended");
    require(
      block.timestamp >= _currentAuction.auctionEndTime,
      "Auction hasn't completed."
    );

    if (_currentAuction.bidder == address(0)) {
      queenPalace.QueenE().burn(_currentAuction.queeneId);
      currentAuction.ended = true;
    } else {
      queenPalace.QueenE().transferFrom(
        address(this),
        _currentAuction.bidder,
        _currentAuction.queeneId
      );

      //transfer funds
      uint256 daoFunds = _currentAuction.lastBidAmount;

      if (daoFunds > 0) _safeDepositToTreasure(daoFunds);

      currentAuction.ended = true;
    }

    emit AuctionEnded(
      _currentAuction.queeneId,
      _currentAuction.bidder,
      _currentAuction.lastBidAmount
    );
  }

  /**
   * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
   */
  function _safeTransferETHWithFallback(address to, uint256 amount) internal {
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

  function _safeDepositToTreasure(uint256 value)
    internal
    returns (bool success)
  {
    (success, ) = payable(queenPalace.RoyalTowerAddr()).call{
      value: value,
      gas: 80000
    }(
      abi.encodeWithSignature(
        "depositToDAOTreasure(uint256)",
        currentAuction.queeneId
      )
    );

    if (!success) fallbackDaoFunds += value;
  }

  /**
   * @notice withdraw fallback funds.
   */
  function withdrawFallbackFund() external nonReentrant {
    require(
      msg.sender == owner() || msg.sender == queenPalace.RoyalTowerAddr(),
      "Invalid Withdrawer"
    );
    (bool successTower, ) = payable(queenPalace.RoyalTowerAddr()).call{
      value: fallbackDaoFunds,
      gas: 80000
    }("");

    if (successTower) {
      emit WithdrawnFallbackFunds(
        queenPalace.RoyalTowerAddr(),
        fallbackDaoFunds
      );
      fallbackDaoFunds = 0;
    }
  }

  function LowerNumber(uint256 firstNumber, uint256 secondNumber)
    private
    pure
    returns (uint256)
  {
    return (firstNumber > secondNumber) ? secondNumber : firstNumber;
  }

  function TransferTokenToOwner(uint256 _tokenId, address _owner)
    external
    onlyOwner
  {
    require(currentAuction.queeneId != _tokenId, "On Auction");

    queenPalace.QueenE().transferFrom(address(this), _owner, _tokenId);
  }
}
// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import {IBaseContractControllerUpgradeable} from "./IBaseContractControllerUpgradeable.sol";

interface IQueenAuctionHouse is IBaseContractControllerUpgradeable {
  event WithdrawnFallbackFunds(address withdrawer, uint256 amount);
  event AuctionSettled(
    uint256 indexed queeneId,
    address settler,
    uint256 amount
  );

  event AuctionStarted(
    uint256 indexed queeneId,
    uint256 startTime,
    uint256 endTime,
    uint256 initialBid
  );
  event AuctionExtended(uint256 indexed queeneId, uint256 endTime);

  event AuctionBid(
    uint256 indexed queeneId,
    address sender,
    uint256 value,
    bool extended
  );

  event AuctionEnded(uint256 indexed queeneId, address winner, uint256 amount);

  event AuctionTimeToleranceUpdated(uint256 timeBuffer);

  event AuctionInitialBidUpdated(uint256 initialBid);

  event AuctionDurationUpdated(uint256 duration);

  event AuctionMinBidIncrementPercentageUpdated(
    uint256 minBidIncrementPercentage
  );

  function endAuction() external;

  function bid(uint256 queeneId) external payable;

  function pause() external;

  function unpause() external;

  function setTimeTolerance(uint256 _timeTolerance) external;

  function setBidRaiseRate(uint8 _bidRaiseRate) external;

  function setInitialBid(uint256 _initialBid) external;

  function setDuration(uint256 _duration) external;
}
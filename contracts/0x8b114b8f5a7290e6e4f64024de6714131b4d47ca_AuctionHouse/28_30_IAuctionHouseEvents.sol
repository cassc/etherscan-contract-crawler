// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/// @title Events emitted by the auction house
/// @notice Contains all events emitted by the auction house
interface IAuctionHouseEvents {
  event NewAuction(
    uint256 indexed round,
    uint256 allowance,
    uint256 targetFloatInEth,
    uint256 startBlock
  );
  event Buy(
    uint256 indexed round,
    address indexed buyer,
    uint256 wethIn,
    uint256 bankIn,
    uint256 floatOut
  );
  event Sell(
    uint256 indexed round,
    address indexed seller,
    uint256 floatIn,
    uint256 wethOut,
    uint256 bankOut
  );
  event ModifyParameters(bytes32 parameter, uint256 data);
  event ModifyParameters(bytes32 parameter, address data);
}
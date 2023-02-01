// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILendingNFT
{
  function orderNFT(
    address _borrower,
    uint8 _nftType,
    uint256 _nftId,
    uint64 _rentalDuration,
    uint256 _dailyRentalPrice
  ) external;

  function cancelOrderItem(
    uint256 _nftId,
    uint8 _nftType
  ) external;

  function paymentOrder(
    uint256 _nftId,
    uint8 _nftType,
    uint256 _startTime,
    string memory _orderUUid,
    bytes memory _signature
  ) external;

  function lenderRewardClaim(
    uint256 _nftId,
    uint8 _nftType,
    string memory _orderUUid,
    bytes memory _signature
  ) external;

  function lenderClaimNFT(
    uint256 _nftId,
    uint8 _nftType,
    string memory _orderUUid,
    bytes memory _signature
  ) external;
}
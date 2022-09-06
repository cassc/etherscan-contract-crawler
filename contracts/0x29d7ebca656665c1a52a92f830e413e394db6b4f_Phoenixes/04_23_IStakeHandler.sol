// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct StakeSummary{
  address owner;  //160
  uint16 tokenId; //176
  uint32 accrued; //208
  uint32 total;   //240
}

interface IStakeHandler{
  function handleClaims( StakeSummary[] calldata stakes ) external;
  function handleStakes( uint256[] calldata tokenIds ) external;
}
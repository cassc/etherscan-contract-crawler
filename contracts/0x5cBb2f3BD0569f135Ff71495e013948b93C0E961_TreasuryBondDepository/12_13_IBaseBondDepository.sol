// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBaseBondDepository {
  struct Bond {
    uint256 principal; // [wad]
    uint256 vestingPeriod; // [seconds]
    uint256 purchased; // [unix timestamp]
    uint256 lastRedeemed; // [unix timestamp]
  }

  function bonds(uint256 _id)
    external
    view
    returns (
      uint256 principal,
      uint256 vestingPeriod,
      uint256 purchased,
      uint256 lastRedeemed
    );

  function listBondIds(address owner)
    external
    view
    returns (uint256[] memory bondIds);

  function listBonds(address owner) external view returns (Bond[] memory);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMaster {
  enum Round {
    Legendary,
    Epic,
    SuperRare,
    Rare,
    Public
  }

  function totalSupply() external view returns(uint);

  function maxSupply() external view returns(uint);

  function fulfillMetaDataRequest(string memory json, uint id, uint tokenId) external;

  function setMetaDataOracleAddress(address newAddress) external;

  function getRoundPrice(Round round) external view returns(uint);

  function showMetaData(uint tokenId) external view returns(string memory);

  function mint(uint[] memory tokenIdxs, address from, string memory name) external;

  function idOccupied(uint tokenId) external view returns(bool);
}
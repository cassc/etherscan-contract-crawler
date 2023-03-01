// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGRDSData {

  function addSymData(uint8 _id, string memory _data, bool _append) external;
  function getSymData(uint8 _id) external view returns (string memory);
}
// SPDX-License-Identifier: GPL

pragma solidity 0.8.9;

interface IStorage {
  function valid(address _address) external view returns (bool);
}
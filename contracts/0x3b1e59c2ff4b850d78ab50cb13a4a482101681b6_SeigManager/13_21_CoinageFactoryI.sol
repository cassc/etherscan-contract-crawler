//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface CoinageFactoryI {
  function deploy() external returns (address);
}
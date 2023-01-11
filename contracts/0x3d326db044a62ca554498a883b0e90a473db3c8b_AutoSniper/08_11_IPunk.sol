// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IPunk {
  function transferPunk(address to, uint punkIndex) external;
}
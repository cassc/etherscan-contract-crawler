// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

interface IPunk {
  function transferPunk(address to, uint punkIndex) external;
}
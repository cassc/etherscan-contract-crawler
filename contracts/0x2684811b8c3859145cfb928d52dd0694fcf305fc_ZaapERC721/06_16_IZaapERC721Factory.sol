// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IZaapERC721Factory {
  function feeReceiver() external view returns (address);

  function feeBPS() external view returns (uint);
}
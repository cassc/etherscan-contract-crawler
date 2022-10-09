// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IWrap721 {
  function emitTransfer(
    address from,
    address to,
    uint256 id,
    uint256 lockId
  ) external;
}

interface IWrap1155 {
  function emitTransfer(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    uint256 lockId
  ) external;
}
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

interface IAlphaWhiteList {
  function whiteListRoutine(
    address _usrAddrs,
    uint64 _assetId,
    uint256 _amount,
    address _erc1155
  ) external returns(bool);
}
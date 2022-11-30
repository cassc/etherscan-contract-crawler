// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IRedeemableContract {
  function burnFromRedeem(address account, uint256 tokenID) external;
}
// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

interface ITokenGate {
  // Intentially same as ERC721's balanceOf
  function balanceOf(address _wallet) external view returns (uint256 balance);
}
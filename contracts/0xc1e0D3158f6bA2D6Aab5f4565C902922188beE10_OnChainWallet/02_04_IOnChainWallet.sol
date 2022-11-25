// SPDX-License-Identifier: MIT

/*
 * Super simple on-line wallet interface
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

interface IOnChainWallet {
  function deposite() external payable;
  function withdraw(uint _amount) external;
  function withdrawAll() external;
  function transfer(address payable _payableTo, uint amount) external;
  function transferAll(address payable _payableTo) external;
}
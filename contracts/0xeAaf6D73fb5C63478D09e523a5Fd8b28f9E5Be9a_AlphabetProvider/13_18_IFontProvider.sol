// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

interface IFontProvider {
  function height() external view returns(uint);
  function baseline() external view returns(uint);
  function widthOf(string memory _char) external view returns(uint);
  function pathOf(string memory _char) external view returns(bytes memory);

  /**
   * This function processes the royalty payment from the decentralized autonomous marketplace. 
   */
  function processPayout() external payable;

  event Payout(string providerKey, address payable to, uint256 amount);
}
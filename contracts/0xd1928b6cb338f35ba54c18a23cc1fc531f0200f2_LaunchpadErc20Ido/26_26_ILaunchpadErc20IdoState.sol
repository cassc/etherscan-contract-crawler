// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface ILaunchpadErc20IdoState {
  struct Collateral {
    bool defined;
    uint256 raised;
  }
}
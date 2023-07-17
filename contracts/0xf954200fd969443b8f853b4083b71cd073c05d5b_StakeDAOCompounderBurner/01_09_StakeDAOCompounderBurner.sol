// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAladdinCompounder } from "../../concentrator/interfaces/IAladdinCompounder.sol";

import { BurnerBase } from "./BurnerBase.sol";

interface IStakeDAOLocker {
  function withdrawExpired(address _user, address _recipient) external returns (uint256 _amount);
}

// solhint-disable no-empty-blocks

contract StakeDAOCompounderBurner is BurnerBase {
  constructor(address _receiver) BurnerBase(_receiver) {}

  /// @notice Burn compounder asset and claim unlocked if possible.
  /// @param _compounder The address compounder.
  function burn(address _compounder) external {
    // redeem to unlock list
    uint256 _balance = IERC20(_compounder).balanceOf(address(this));
    if (_balance > 0) {
      IAladdinCompounder(_compounder).redeem(_balance, receiver, address(this));
    }

    // withdraw unlocked
    IStakeDAOLocker(_compounder).withdrawExpired(receiver, receiver);
  }
}
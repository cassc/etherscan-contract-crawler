// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAladdinCompounder } from "../../concentrator/interfaces/IAladdinCompounder.sol";

import { BurnerBase } from "./BurnerBase.sol";

interface IConvexFraxStrategy {
  function claim(address _account) external;
}

// solhint-disable no-empty-blocks

contract ConvexFraxCompounderBurner is BurnerBase {
  constructor(address _receiver) BurnerBase(_receiver) {}

  /// @notice Burn compounder asset and claim unlocked if possible.
  /// @param _compounder The address compounder.
  /// @param _strategy The corresponding strategy.
  function burn(address _compounder, address _strategy) external {
    // redeem to unlock list
    uint256 _balance = IERC20(_compounder).balanceOf(address(this));
    if (_balance > 0) {
      IAladdinCompounder(_compounder).redeem(_balance, receiver, address(this));
    }

    // withdraw unlocked
    IConvexFraxStrategy(_strategy).claim(receiver);
  }
}
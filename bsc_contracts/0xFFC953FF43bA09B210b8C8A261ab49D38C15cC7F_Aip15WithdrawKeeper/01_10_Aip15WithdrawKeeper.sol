// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.12;

import { Ownable } from "./Ownable.sol";
import { BasicKeepers } from "./BasicKeepers.sol";
import { IERC20 } from "./IERC20.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";
import { KeeperCompatibleInterface } from "./KeeperCompatible.sol";
import { IFairLaunch } from "./IFairLaunch.sol";
import { IAip15 } from "./IAip15.sol";

/// @title Aip15WithdrawKeeper - A Chainlink's Keepers compatible contract
/// for withdraw Aip15 rewards once 240,000 ALPACA reached.
/// @dev The downstream contract must implement the IAip15 interface.
/// @author spicysquid168
// solhint-disable not-rely-on-time
contract Aip15WithdrawKeeper is
  Ownable,
  ReentrancyGuard,
  BasicKeepers,
  KeeperCompatibleInterface
{
  /// Errors
  error Aip15WithdrawKeeper_NotPassTriggerWei();

  /// Configs
  IAip15 public aip15;
  IFairLaunch public fairLaunch;
  IERC20 public alpaca;

  /// Events
  event LogPerformUpkeep(uint256 _timestamp);
  event LogSetTriggerWei(uint256 _prevTriggerWei, uint256 _triggerWei);

  constructor(
    string memory _name,
    IAip15 _aip15,
    IFairLaunch _fairLaunch
  ) BasicKeepers(_name) {
    // Effect
    aip15 = _aip15;
    fairLaunch = _fairLaunch;
    alpaca = IERC20(_fairLaunch.alpaca());
  }

  function checkUpkeep(
    bytes calldata /* _checkData */
  ) external view override returns (bool, bytes memory) {
    return (
      alpaca.balanceOf(address(aip15)) +
        fairLaunch.pendingAlpaca(29, address(aip15)) >=
        aip15.targetEmission()
        ? true
        : false,
      ""
    );
  }

  function performUpkeep(
    bytes calldata /* _performData */
  ) external nonReentrant {
    // Interaction
    aip15.withdrawFebEmissionDummy();
    emit LogPerformUpkeep(block.timestamp);
  }
}

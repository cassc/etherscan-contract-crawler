// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FurProxy.sol";
import "./FurLib.sol";
import "../Furballs.sol";

/// @title Stakeholders
/// @author LFG Gaming LLC
/// @notice Tracks "percent ownership" of a smart contract, paying out according to schedule
/// @dev Acts as a treasury, receiving ETH funds and distributing them to stakeholders
abstract contract Stakeholders is FurProxy {
  // stakeholder values, in 1/1000th of a percent (received during withdrawls)
  mapping(address => uint64) public stakes;

  // List of stakeholders.
  address[] public stakeholders;

  // Where any remaining funds should be deposited. Defaults to contract creator.
  address payable public poolAddress;

  constructor(address furballsAddress) FurProxy(furballsAddress) {
    poolAddress = payable(msg.sender);
  }

  /// @notice Overflow pool of funds. Contains remaining funds from withdrawl.
  function setPool(address addr) public onlyOwner {
    poolAddress = payable(addr);
  }

  /// @notice Changes payout percentages.
  function setStakeholder(address addr, uint64 stake) public onlyOwner {
    if (!_hasStakeholder(addr)) {
      stakeholders.push(addr);
    }
    uint64 percent = stake;
    for (uint256 i=0; i<stakeholders.length; i++) {
      if (stakeholders[i] != addr) {
        percent += stakes[stakeholders[i]];
      }
    }

    require(percent <= FurLib.OneHundredPercent, "Invalid stake (exceeds 100%)");
    stakes[addr] = stake;
  }

  /// @notice Empties this contract's balance, paying out to stakeholders.
  function withdraw() external gameAdmin {
    uint256 balance = address(this).balance;
    require(balance >= FurLib.OneHundredPercent, "Insufficient balance");

    for (uint256 i=0; i<stakeholders.length; i++) {
      address addr = stakeholders[i];
      uint256 payout = balance * uint256(stakes[addr]) / FurLib.OneHundredPercent;
      if (payout > 0) {
        payable(addr).transfer(payout);
      }
    }
    uint256 remaining = address(this).balance;
    poolAddress.transfer(remaining);
  }

  /// @notice Check
  function _hasStakeholder(address addr) internal view returns(bool) {
    for (uint256 i=0; i<stakeholders.length; i++) {
      if (stakeholders[i] == addr) {
        return true;
      }
    }
    return false;
  }

  // -----------------------------------------------------------------------------------------------
  // Payable
  // -----------------------------------------------------------------------------------------------

  /// @notice This contract can be paid transaction fees, e.g., from OpenSea
  /// @dev The contractURI specifies itself as the recipient of transaction fees
  receive() external payable { }
}
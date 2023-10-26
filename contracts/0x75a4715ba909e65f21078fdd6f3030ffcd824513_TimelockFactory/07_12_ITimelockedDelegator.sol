// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IDelegatable is IERC20 {
  function delegate(address delegatee) external;
}

/// @title TimelockedDelegator interface
/// @author Fei Protocol
/// @dev Modified from: https://github.com/fei-protocol/fei-protocol-core/blob/develop/contracts/timelocks/ITimelockedDelegator.sol
interface ITimelockedDelegator {
  // ----------- Events -----------

  event Delegate(address indexed _delegatee, uint256 _amount);

  event Undelegate(address indexed _delegatee, uint256 _amount);

  // ----------- Beneficiary only state changing api -----------

  function delegate(address delegatee, uint256 amount) external;

  function undelegate(address delegatee) external returns (uint256);

  // ----------- Getters -----------

  function delegateContract(address delegatee) external view returns (address);

  function delegateAmount(address delegatee) external view returns (uint256);

  function totalDelegated() external view returns (uint256);

  function token() external view returns (IDelegatable);
}
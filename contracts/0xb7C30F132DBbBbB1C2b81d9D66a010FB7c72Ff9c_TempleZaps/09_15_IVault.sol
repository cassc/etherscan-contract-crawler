pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IVault {
  function depositFor(address _account, uint256 _amount) external; 
}
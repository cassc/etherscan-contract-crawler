// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity >0.6.0;

interface IRewardsEscrow {
  function lock(
    address _address,
    uint256 _amount,
    uint256 duration
  ) external;

  function addAuthorizedContract(address _staking) external;

  function removeAuthorizedContract(address _staking) external;
}
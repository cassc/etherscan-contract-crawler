// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @dev SmoltingInu token interface
 */

interface ISmoltingInu is IERC20 {
  function gameMint(address _user, uint256 _amount) external;

  function gameBurn(address _user, uint256 _amount) external;

  function addPlayThrough(
    address _user,
    uint256 _amountWagered,
    uint8 _percentContribution
  ) external;

  function setCanSellWithoutElevation(address _wallet, bool _canSellWithoutElev)
    external;
}
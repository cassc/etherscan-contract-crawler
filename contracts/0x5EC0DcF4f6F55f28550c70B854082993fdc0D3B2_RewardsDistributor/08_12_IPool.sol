// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';

interface IPool {

  event AuthorizedStrategy(address indexed strategy);
  event UnauthorizedStrategy(address indexed strategy);
  event Paused(address indexed sender);
  event Unpaused(address indexed sender);
  event WithdrawToken(
    IERC20Ext indexed token,
    address indexed sender,
    address indexed recipient,
    uint256 amount
  );

  function pause() external;
  function unpause() external;
  function authorizeStrategies(address[] calldata strategies) external;
  function unauthorizeStrategies(address[] calldata strategies) external;
  function withdrawFunds(
    IERC20Ext[] calldata tokens,
    uint256[] calldata amounts,
    address payable recipient
  ) external;
  function isPaused() external view returns (bool);
  function isAuthorizedStrategy(address strategy) external view returns (bool);
  function getAuthorizedStrategiesLength() external view returns (uint256);
  function getAuthorizedStrategyAt(uint256 index) external view returns (address);
  function getAllAuthorizedStrategies()
    external view returns (address[] memory strategies);
}
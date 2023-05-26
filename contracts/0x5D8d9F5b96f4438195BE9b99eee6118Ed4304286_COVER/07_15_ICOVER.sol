// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

import "../ERC20/IERC20.sol";

/**
 * @title Interface of COVER
 * @author [email protected]
 */
interface ICOVER is IERC20 {
  function mint(address _account, uint256 _amount) external;
  function setBlacksmith(address _newBlacksmith) external returns (bool);
  function setMigrator(address _newMigrator) external returns (bool);
}
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import { AccessManager } from "../lib/AccessManager.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStake } from "../interfaces/IStake.sol";
import { PercentageMath } from "../lib/aave/PercentageMath.sol";

/**
 * @title Slasher
 * @dev A contract to manage slashing and cooldown admin for the Stake contract
 */
contract Slasher is AccessManager {
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  // Slasher roles
  bytes32 public constant SLASH_ADMIN_ROLE = keccak256("SLASHER_ROLE");
  bytes32 public constant COOLDOWN_ADMIN_ROLE = keccak256("COOLDOWN_ROLE");

  // Stake contracts roles
  uint256 public constant STAKE_SLASH_ADMIN_ROLE = 0;
  uint256 public constant STAKE_COOLDOWN_ADMIN_ROLE = 1;

  /**
   * @dev Initializes the main admin role
   * @param admin the address of the main admin role
   */
  constructor(address admin) AccessManager(admin) {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Executes a slashing of the underlying of a certain amount on a stake contract, transferring the seized funds
   * to destination. Decreasing the amount of underlying will automatically adjust the exchange rate
   * @param stake the address of the contract to be slashed
   * @param destination the address where seized funds will be transferred
   * @param amount the amount
   **/
  function slash(
    IStake stake,
    address destination,
    uint256 amount
  ) external onlyAdminOrRole(SLASH_ADMIN_ROLE) {
    stake.slash(destination, amount);
  }

  /**
   * @dev Executes a slashing of the underlying of the max amount on a stake contract, transferring the seized funds
   * to destination. Decreasing the amount of underlying will automatically adjust the exchange rate
   * @param stake the address of the contract to be slashed
   * @param destination the address where seized funds will be transferred
   **/
  function slashMax(IStake stake, address destination) external onlyAdminOrRole(SLASH_ADMIN_ROLE) {
    uint256 maxSlashable = getMaxSlashableAmount(stake);
    stake.slash(destination, maxSlashable);
  }

  /**
   * @dev sets the state of the cooldown pause
   * @param stake the address of the contract
   * @param paused true if the cooldown needs to be paused, false otherwise
   */
  function setCooldownPause(IStake stake, bool paused) external onlyAdminOrRole(COOLDOWN_ADMIN_ROLE) {
    stake.setCooldownPause(paused);
  }

  /**
   * @dev sets the pending admin for a specific role
   * @param stake the address of the contract
   * @param stakeRole the role in the stake contract associated with the new pending admin being set
   * @param newPendingAdmin the address of the new pending admin for the role
   **/
  function setStakePendingAdmin(
    IStake stake,
    uint256 stakeRole,
    address newPendingAdmin
  ) external onlyAdminOrRole(_getAdminRole(stakeRole)) {
    stake.setPendingAdmin(stakeRole, newPendingAdmin);
  }

  /**
   * @dev allows the caller to become a specific role admin
   * @param stake the address of the contract
   * @param stakeRole the role in the stake contract associated with the admin claiming the new role
   **/
  function claimStakeRoleAdmin(IStake stake, uint256 stakeRole) external onlyAdminOrRole(_getAdminRole(stakeRole)) {
    stake.claimRoleAdmin(stakeRole);
  }

  /**
   * @dev Moves `amount` tokens to `recipient`. This method is intended to be used to rescue any accidentally locked funds.
   * @param token the address of the token contract
   * @param recipient The address of the recipient
   * @param amount The amount of tokens to be transferred
   */
  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.safeTransfer(recipient, amount);
  }

  /**
   * @dev returns the current maximum slashable amount of the stake
   */
  function getMaxSlashableAmount(IStake stake) public view returns (uint256) {
    address stakedToken = stake.STAKED_TOKEN();
    uint256 balance = IERC20(stakedToken).balanceOf(address(stake));
    uint256 maxSlashablePercentage = stake.getMaxSlashablePercentage();
    return balance.percentMul(maxSlashablePercentage);
  }

  /**
   * @dev Returns the related role on this contract to a role on the stake contract
   * @param stakeAdminRole the role on the stake contract
   */
  function _getAdminRole(uint256 stakeAdminRole) internal pure returns (bytes32) {
    if (stakeAdminRole == STAKE_SLASH_ADMIN_ROLE) {
      return SLASH_ADMIN_ROLE;
    } else if (stakeAdminRole == STAKE_COOLDOWN_ADMIN_ROLE) {
      return COOLDOWN_ADMIN_ROLE;
    } else {
      revert("INVALID_ADMIN_ROLE");
    }
  }
}
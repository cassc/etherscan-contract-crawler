// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../libraries/TransferHelper.sol';
import '../interfaces/IVestingPlans.sol';
import '../interfaces/ILockupPlans.sol';

/// @title BatchPlanner - contract to create batches of lockup and vesting plans in bulk

contract BatchPlanner {

  /// @dev struct object that defines the parameters of a general lockup and vesting plan, that are shared by both lockup and vesting plans
  /// @param recipient is the address of the wallet receiving the plan
  /// @param amount is the amount of tokens to be locked in the plan
  /// @param start is the unix timestamp of when unlocking or vesting starts
  /// @param cliff is an optional cliff date when the plan has a second discrete date after the start when an initial chunk unlocks / vests
  /// @param rate is the amount of tokens that unlock or vest per period
  struct Plan {
    address recipient;
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
  }
  /// @dev event used for internal analytics and reporting only
  event BatchCreated(address indexed creator, address token, uint256 recipients, uint256 totalAmount, uint8 mintType);


  /// @notice function to create a batch of lockup plans
  /// @dev the function will pull in the entire balancde of totalAmount into the contract, then increase the approval allowance and then via loop mint lockup plans
  /// @param locker is the address of the lockup plan that the tokens will be locked in, and NFT plan provided to
  /// @param token is the address of the token that is given and locked to the individuals
  /// @param totalAmount is the total amount of tokens being locked, this has to equal the sum of all the individual amounts in the plans struct
  /// @param plans is the array of plans that contain each plan parameters
  /// @param period is the length of the period in seconds that tokens become unlocked / vested
  /// @param mintType is an internal tool to help with identifying front end applications
  function batchLockingPlans(
    address locker,
    address token,
    uint256 totalAmount,
    Plan[] calldata plans,
    uint256 period,
    uint8 mintType
  ) external {
    require(totalAmount > 0, '0_totalAmount');
    require(locker != address(0), '0_locker');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), locker, totalAmount);
    uint256 amountCheck;
    for (uint16 i; i < plans.length; i++) {
      ILockupPlans(locker).createPlan(
        plans[i].recipient,
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        period
      );
      amountCheck += plans[i].amount;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit BatchCreated(msg.sender, token, plans.length, totalAmount, mintType);
  }


  /// @notice function to create a batch of vesting plans.
  /// @dev the function will pull in the entire balance of totalAmount to the contract, increase the allowance and then via loop mint vesting plans
  /// @param locker is the address of the lockup plan that the tokens will be locked in, and NFT plan provided to
  /// @param token is the address of the token that is given and locked to the individuals
  /// @param totalAmount is the total amount of tokens being locked, this has to equal the sum of all the individual amounts in the plans struct
  /// @param plans is the array of plans that contain each plan parameters
  /// @param period is the length of the period in seconds that tokens become unlocked / vested
  /// @param vestingAdmin is the address of the vesting admin, that will be the same for all plans created
  /// @param adminTransferOBO is an emergency toggle that allows the vesting admin to tranfer a vesting plan on behalf of a beneficiary
  /// @param mintType is an internal tool to help with identifying front end applications
  function batchVestingPlans(
    address locker,
    address token,
    uint256 totalAmount,
    Plan[] calldata plans,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO,
    uint8 mintType
  ) external {
    require(totalAmount > 0, '0_totalAmount');
    require(locker != address(0), '0_locker');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), locker, totalAmount);
    uint256 amountCheck;
    for (uint16 i; i < plans.length; i++) {
      IVestingPlans(locker).createPlan(
        plans[i].recipient,
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        period,
        vestingAdmin,
        adminTransferOBO
      );
      amountCheck += plans[i].amount;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit BatchCreated(msg.sender, token, plans.length, totalAmount, mintType);
  }
}
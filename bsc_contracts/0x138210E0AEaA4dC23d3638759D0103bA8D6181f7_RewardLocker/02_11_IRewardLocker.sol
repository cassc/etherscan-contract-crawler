// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardLocker {
  struct VestingSchedule {
    uint64 startBlock;
    uint64 endBlock;
    uint128 quantity;
    uint128 vestedQuantity;
  }

  event VestingEntryCreated(
    IERC20 indexed token,
    address indexed beneficiary,
    uint256 startBlock,
    uint256 endBlock,
    uint256 quantity,
    uint256 index
  );

  event VestingEntryQueued(
    uint256 indexed index,
    IERC20 indexed token,
    address indexed beneficiary,
    uint256 quantity
  );

  event Vested(
    IERC20 indexed token,
    address indexed beneficiary,
    uint256 vestedQuantity,
    uint256 index
  );

  /**
   * @dev queue a vesting schedule starting from now
   */
  function lock(
    IERC20 token,
    address account,
    uint256 amount
  ) external payable;

  /**
   * @dev queue a vesting schedule
   */
  function lockWithStartBlock(
    IERC20 token,
    address account,
    uint256 quantity,
    uint256 startBlock
  ) external payable;

  /**
   * @dev vest all completed schedules for multiple tokens
   */
  function vestCompletedSchedulesForMultipleTokens(IERC20[] calldata tokens)
    external
    returns (uint256[] memory vestedAmounts);

  
  /**
   * @dev for all completed schedule, claim token
   */
  function vestCompletedSchedules(IERC20 token) external returns (uint256);

 
  /**
   * @dev length of vesting schedules array
   */
  function numVestingSchedules(address account, IERC20 token) external view returns (uint256);

  /**
   * @dev get detailed of each vesting schedule
   */
  function getVestingScheduleAtIndex(
    address account,
    IERC20 token,
    uint256 index
  ) external view returns (VestingSchedule memory);

  /**
   * @dev get vesting shedules array
   */
  function getVestingSchedules(address account, IERC20 token)
    external
    view
    returns (VestingSchedule[] memory schedules);
}
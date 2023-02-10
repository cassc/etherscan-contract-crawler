// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IERC20Ext} from './IERC20Ext.sol';
import {SafeMath} from './SafeMath.sol';
import {SafeCast} from './SafeCast.sol';
import {SafeERC20} from './SafeERC20.sol';
import {EnumerableSet} from './EnumerableSet.sol';
import {PermissionAdmin} from '/PermissionAdmin.sol';

import {ILyfeblocRewardLocker} from './ILyfeblocRewardLocker.sol';

contract LyfeblocRewardLocker is ILyfeblocRewardLocker, PermissionAdmin {
  using SafeMath for uint256;
  using SafeCast for uint256;

  using SafeERC20 for IERC20Ext;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct VestingSchedules {
    uint256 length;
    mapping(uint256 => VestingSchedule) data;
  }

  uint256 private constant MAX_REWARD_CONTRACTS_SIZE = 100;

  /// @dev whitelist of reward contracts
  mapping(IERC20Ext => EnumerableSet.AddressSet) internal rewardContractsPerToken;

  /// @dev vesting schedule of an account
  mapping(address => mapping(IERC20Ext => VestingSchedules)) private accountVestingSchedules;

  /// @dev An account's total escrowed balance per token to save recomputing this for fee extraction purposes
  mapping(address => mapping(IERC20Ext => uint256)) public accountEscrowedBalance;

  /// @dev An account's total vested reward per token
  mapping(address => mapping(IERC20Ext => uint256)) public accountVestedBalance;

  /* ========== EVENTS ========== */
  event RewardContractAdded(address indexed rewardContract, IERC20Ext indexed token, bool isAdded);

  /* ========== MODIFIERS ========== */

  modifier onlyRewardsContract(IERC20Ext token) {
    require(rewardContractsPerToken[token].contains(msg.sender), 'only reward contract');
    _;
  }

  constructor(address _admin) PermissionAdmin(_admin) {}

  /**
   * @notice Add a whitelisted rewards contract
   */
  function addRewardsContract(IERC20Ext token, address _rewardContract) external onlyAdmin {
    require(
      rewardContractsPerToken[token].length() < MAX_REWARD_CONTRACTS_SIZE,
      'rewardContracts is too long'
    );
    require(rewardContractsPerToken[token].add(_rewardContract), '_rewardContract is added');

    emit RewardContractAdded(_rewardContract, token, true);
  }

  /**
   * @notice Remove a whitelisted rewards contract
   */
  function removeRewardsContract(IERC20Ext token, address _rewardContract) external onlyAdmin {
    require(rewardContractsPerToken[token].remove(_rewardContract), '_rewardContract is removed');

    emit RewardContractAdded(_rewardContract, token, false);
  }

  function lock(
    IERC20Ext token,
    address account,
    uint256 quantity,
    uint32 vestingDuration
  ) external override payable {
    lockWithStartTime(token, account, quantity, _getBlockTime(), vestingDuration);
  }

  /**
   * @dev vest all completed schedules for multiple tokens
   */
  function vestCompletedSchedulesForMultipleTokens(IERC20Ext[] calldata tokens)
    external
    override
    returns (uint256[] memory vestedAmounts)
  {
    vestedAmounts = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      vestedAmounts[i] = vestCompletedSchedules(tokens[i]);
    }
  }

  /**
   * @dev claim multiple tokens for specific vesting schedule,
   *      if schedule has not ended yet, claiming amounts are linear with vesting times
   */
  function vestScheduleForMultipleTokensAtIndices(
    IERC20Ext[] calldata tokens,
    uint256[][] calldata indices
  ) external override returns (uint256[] memory vestedAmounts) {
    require(tokens.length == indices.length, 'tokens.length != indices.length');
    vestedAmounts = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      vestedAmounts[i] = vestScheduleAtIndices(tokens[i], indices[i]);
    }
  }

  function lockWithStartTime(
    IERC20Ext token,
    address account,
    uint256 quantity,
    uint256 startTime,
    uint32 vestingDuration
  ) public override payable onlyRewardsContract(token) {
    require(quantity > 0, '0 quantity');

    VestingSchedules storage schedules = accountVestingSchedules[account][token];
    uint256 endTime = startTime.add(vestingDuration);
    uint256 schedulesLength = schedules.length;

    if (vestingDuration == 0) {
      // append new schedule
      schedules.data[schedulesLength] = VestingSchedule({
        startTime: startTime.toUint64(),
        endTime: endTime.toUint64(),
        quantity: quantity.toUint128(),
        vestedQuantity: quantity.toUint128()
      });
      accountVestedBalance[account][token] = accountVestedBalance[account][token].add(
        quantity
      );
      if (token == IERC20Ext(0)) {
        require(msg.value == quantity, 'Invalid msg.value');
        (bool success, ) = account.call{value: quantity}('');
        require(success, 'fail to transfer');
      } else {
        // transfer token from reward contract to receiver
        token.safeTransferFrom(msg.sender, account, quantity);
      }
      emit VestingEntryCreated(token, account, startTime, endTime, quantity, schedulesLength);
      emit Vested(token, account, quantity, schedulesLength);
    } else {
      if (token == IERC20Ext(0)) {
        require(msg.value == quantity, 'Invalid msg.value');
      } else {
        // transfer token from reward contract to lock contract
        token.safeTransferFrom(msg.sender, address(this), quantity);
      }
      // combine with the last schedule if they have the same start & end times
      if (schedulesLength > 0) {
        VestingSchedule storage lastSchedule = schedules.data[schedulesLength - 1];
        if (lastSchedule.startTime == startTime && lastSchedule.endTime == endTime) {
          lastSchedule.quantity = uint256(lastSchedule.quantity).add(quantity).toUint128();
          accountEscrowedBalance[account][token] = accountEscrowedBalance[account][token].add(
            quantity
          );
          emit VestingEntryQueued(schedulesLength - 1, token, account, quantity);
          return;
        }
      }
      // append new schedule
      schedules.data[schedulesLength] = VestingSchedule({
        startTime: startTime.toUint64(),
        endTime: endTime.toUint64(),
        quantity: quantity.toUint128(),
        vestedQuantity: 0
      });
      // record total vesting balance of user
      accountEscrowedBalance[account][token] = accountEscrowedBalance[account][token].add(quantity);
      emit VestingEntryCreated(token, account, startTime, endTime, quantity, schedulesLength);
    }
    schedules.length = schedulesLength + 1;
  }

  /**
   * @dev Allow a user to vest all ended schedules
   */
  function vestCompletedSchedules(IERC20Ext token) public override returns (uint256) {
    VestingSchedules storage schedules = accountVestingSchedules[msg.sender][token];
    uint256 schedulesLength = schedules.length;

    uint256 totalVesting = 0;
    for (uint256 i = 0; i < schedulesLength; i++) {
      VestingSchedule memory schedule = schedules.data[i];
      if (_getBlockTime() < schedule.endTime) {
        continue;
      }
      uint256 vestQuantity = uint256(schedule.quantity).sub(schedule.vestedQuantity);
      if (vestQuantity == 0) {
        continue;
      }
      schedules.data[i].vestedQuantity = schedule.quantity;
      totalVesting = totalVesting.add(vestQuantity);

      emit Vested(token, msg.sender, vestQuantity, i);
    }
    _completeVesting(token, totalVesting);

    return totalVesting;
  }

  /**
   * @notice Allow a user to vest with specific schedule
   */
  function vestScheduleAtIndices(IERC20Ext token, uint256[] memory indexes)
    public
    override
    returns (uint256)
  {
    VestingSchedules storage schedules = accountVestingSchedules[msg.sender][token];
    uint256 schedulesLength = schedules.length;
    uint256 totalVesting = 0;
    for (uint256 i = 0; i < indexes.length; i++) {
      require(indexes[i] < schedulesLength, 'invalid schedule index');
      VestingSchedule memory schedule = schedules.data[indexes[i]];
      uint256 vestQuantity = _getVestingQuantity(schedule);
      if (vestQuantity == 0) {
        continue;
      }
      schedules.data[indexes[i]].vestedQuantity = uint256(schedule.vestedQuantity)
        .add(vestQuantity)
        .toUint128();

      totalVesting = totalVesting.add(vestQuantity);

      emit Vested(token, msg.sender, vestQuantity, indexes[i]);
    }
    _completeVesting(token, totalVesting);
    return totalVesting;
  }

  function vestSchedulesInRange(
    IERC20Ext token,
    uint256 startIndex,
    uint256 endIndex
  ) public override returns (uint256) {
    require(startIndex <= endIndex, 'startIndex > endIndex');
    uint256[] memory indexes = new uint256[](endIndex - startIndex + 1);
    for (uint256 index = startIndex; index <= endIndex; index++) {
      indexes[index - startIndex] = index;
    }
    return vestScheduleAtIndices(token, indexes);
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * @notice The number of vesting dates in an account's schedule.
   */
  function numVestingSchedules(address account, IERC20Ext token)
    external
    override
    view
    returns (uint256)
  {
    return accountVestingSchedules[account][token].length;
  }

  /**
   * @dev manually get vesting schedule at index
   */
  function getVestingScheduleAtIndex(
    address account,
    IERC20Ext token,
    uint256 index
  ) external override view returns (VestingSchedule memory) {
    return accountVestingSchedules[account][token].data[index];
  }

  /**
   * @dev Get all schedules for an account.
   */
  function getVestingSchedules(address account, IERC20Ext token)
    external
    override
    view
    returns (VestingSchedule[] memory schedules)
  {
    uint256 schedulesLength = accountVestingSchedules[account][token].length;
    schedules = new VestingSchedule[](schedulesLength);
    for (uint256 i = 0; i < schedulesLength; i++) {
      schedules[i] = accountVestingSchedules[account][token].data[i];
    }
  }

  function getRewardContractsPerToken(IERC20Ext token)
    external
    view
    returns (address[] memory rewardContracts)
  {
    rewardContracts = new address[](rewardContractsPerToken[token].length());
    for (uint256 i = 0; i < rewardContracts.length; i++) {
      rewardContracts[i] = rewardContractsPerToken[token].at(i);
    }
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  function _completeVesting(IERC20Ext token, uint256 totalVesting) internal {
    require(totalVesting != 0, '0 vesting amount');
    accountEscrowedBalance[msg.sender][token] = accountEscrowedBalance[msg.sender][token].sub(
      totalVesting
    );
    accountVestedBalance[msg.sender][token] = accountVestedBalance[msg.sender][token].add(
      totalVesting
    );

    if (token == IERC20Ext(0)) {
      (bool success, ) = msg.sender.call{value: totalVesting}('');
      require(success, 'fail to transfer');
    } else {
      token.safeTransfer(msg.sender, totalVesting);
    }
  }

  /**
   * @dev implements linear vesting mechanism
   */
  function _getVestingQuantity(VestingSchedule memory schedule) internal view returns (uint256) {
    if (_getBlockTime() >= uint256(schedule.endTime)) {
      return uint256(schedule.quantity).sub(schedule.vestedQuantity);
    }
    if (_getBlockTime() <= uint256(schedule.startTime)) {
      return 0;
    }
    uint256 lockDuration = uint256(schedule.endTime).sub(schedule.startTime);
    uint256 passedDuration = _getBlockTime() - uint256(schedule.startTime);
    return passedDuration.mul(schedule.quantity).div(lockDuration).sub(schedule.vestedQuantity);
  }

  /**
   * @dev wrap block.timestamp so we can easily mock it
   */
  function _getBlockTime() internal virtual view returns (uint32) {
    return uint32(block.timestamp);
  }
}
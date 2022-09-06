// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IERC20Ext} from './IERC20Ext.sol';
import {SafeMath} from './SafeMath.sol';
import {SafeCast} from './SafeCast.sol';
import {SafeERC20} from './SafeERC20.sol';
import {EnumerableSet} from './EnumerableSet.sol';
import {PermissionAdmin} from './PermissionAdmin.sol';

import {IKyberRewardLocker} from './IKyberRewardLocker.sol';

/// https://github.com/KyberNetwork/dao_sc/blob/f3b68ac30343f5bb03595ba1522eefd0dfba82ed/contracts/liquidityMining/KyberRewardLocker.sol
contract KyberRewardLocker is IKyberRewardLocker, PermissionAdmin {
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

  /// @dev vesting duration for earch token
  mapping(IERC20Ext => uint256) public vestingDurationPerToken;

  /* ========== EVENTS ========== */
  event RewardContractAdded(address indexed rewardContract, IERC20Ext indexed token, bool isAdded);
  event SetVestingDuration(IERC20Ext indexed token, uint64 vestingDuration);

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

  function setVestingDuration(IERC20Ext token, uint64 _vestingDuration) external onlyAdmin {
    vestingDurationPerToken[token] = _vestingDuration;

    emit SetVestingDuration(token, _vestingDuration);
  }

  function lock(
    IERC20Ext token,
    address account,
    uint256 quantity
  ) external override payable {
    lockWithStartBlock(token, account, quantity, _blockNumber());
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
   *      if schedule has not ended yet, claiming amounts are linear with vesting blocks
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

  function lockWithStartBlock(
    IERC20Ext token,
    address account,
    uint256 quantity,
    uint256 startBlock
  ) public override payable onlyRewardsContract(token) {
    require(quantity > 0, '0 quantity');

    if (token == IERC20Ext(0)) {
      require(msg.value == quantity, 'Invalid msg.value');
    } else {
      // transfer token from reward contract to lock contract
      token.safeTransferFrom(msg.sender, address(this), quantity);
    }

    VestingSchedules storage schedules = accountVestingSchedules[account][token];
    uint256 schedulesLength = schedules.length;
    uint256 endBlock = startBlock.add(vestingDurationPerToken[token]);

    // combine with the last schedule if they have the same start & end blocks
    if (schedulesLength > 0) {
      VestingSchedule storage lastSchedule = schedules.data[schedulesLength - 1];
      if (lastSchedule.startBlock == startBlock && lastSchedule.endBlock == endBlock) {
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
      startBlock: startBlock.toUint64(),
      endBlock: endBlock.toUint64(),
      quantity: quantity.toUint128(),
      vestedQuantity: 0
    });
    schedules.length = schedulesLength + 1;
    // record total vesting balance of user
    accountEscrowedBalance[account][token] = accountEscrowedBalance[account][token].add(quantity);

    emit VestingEntryCreated(token, account, startBlock, endBlock, quantity, schedulesLength);
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
      if (_blockNumber() < schedule.endBlock) {
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
    if (_blockNumber() >= uint256(schedule.endBlock)) {
      return uint256(schedule.quantity).sub(schedule.vestedQuantity);
    }
    if (_blockNumber() <= uint256(schedule.startBlock)) {
      return 0;
    }
    uint256 lockDuration = uint256(schedule.endBlock).sub(schedule.startBlock);
    uint256 passedDuration = _blockNumber() - uint256(schedule.startBlock);
    return passedDuration.mul(schedule.quantity).div(lockDuration).sub(schedule.vestedQuantity);
  }

  /**
   * @dev wrap block.number so we can easily mock it
   */
  function _blockNumber() internal virtual view returns (uint256) {
    return block.number;
  }
}
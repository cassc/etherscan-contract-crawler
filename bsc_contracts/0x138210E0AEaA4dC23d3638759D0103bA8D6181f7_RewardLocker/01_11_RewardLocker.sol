// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./IRewardLocker.sol";

contract RewardLocker is IRewardLocker, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeCast for uint256;

  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct VestingSchedules {
    uint256 length;
    mapping(uint256 => VestingSchedule) data;
  }

  uint256 public MAX_REWARD_CONTRACTS_SIZE = 100;
  uint256 constant MAX_VESTING_DURATION = 14400000; // Safety check - 1 year

  /// @dev whitelist of reward contracts
  mapping(IERC20 => EnumerableSet.AddressSet) internal rewardContractsPerToken;

  /// @dev vesting schedule of an account
  mapping(address => mapping(IERC20 => VestingSchedules)) private accountVestingSchedules;

  /// @dev An account's total escrowed balance per token to save recomputing this for fee extraction purposes
  mapping(address => mapping(IERC20 => uint256)) public accountEscrowedBalance;

  /// @dev An account's total vested reward per token
  mapping(address => mapping(IERC20 => uint256)) public accountVestedBalance;

  /// @dev vesting duration for earch token
  mapping(IERC20 => uint256) public vestingDurationPerToken;

  /* ========== EVENTS ========== */
  event RewardContractAdded(address indexed rewardContract, IERC20 indexed token, bool isAdded);
  event SetVestingDuration(IERC20 indexed token, uint64 vestingDuration);
  event Vest(IERC20 indexed token, uint256 totalVesting);
  event UpdateMaxContractSize(uint256 size);


  function setVestingDuration(IERC20 token, uint64 _vestingDuration) external onlyOwner {
    require(_vestingDuration <= MAX_VESTING_DURATION, "!overmax");
    vestingDurationPerToken[token] = _vestingDuration;

    emit SetVestingDuration(token, _vestingDuration);
  }

  function lock(
    IERC20 token,
    address account,
    uint256 quantity
  ) external override payable nonReentrant {
    _lockWithStartBlock(token, account, quantity, _blockNumber());
  }

  /**
   * @dev vest all completed schedules for multiple tokens
   */
  function vestCompletedSchedulesForMultipleTokens(IERC20[] calldata tokens)
    external
    override
    returns (uint256[] memory vestedAmounts)
  {
    vestedAmounts = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      vestedAmounts[i] = vestCompletedSchedules(tokens[i]);
    }
  }

    function bulkLock(IERC20 token, address[] calldata accounts, uint256[] calldata quantities, uint256 startBlock) external onlyOwner
    {
        for (uint256 i=0;i<accounts.length;i++) {
            this.lockWithStartBlock(token,accounts[i], quantities[i], startBlock);
        }
    }

  function lockWithStartBlock(
    IERC20 token,
    address account,
    uint256 quantity,
    uint256 startBlock
  ) external override payable {
    _lockWithStartBlock(token, account, quantity, startBlock);
  }
  
  function _lockWithStartBlock(
    IERC20 token,
    address account,
    uint256 quantity,
    uint256 startBlock
  ) internal {
    require(quantity > 0, '0 quantity');

    if (token == IERC20(0)) {
      require(msg.value == quantity, 'Invalid msg.value');
    } else {
      // transfer token from reward contract to lock contract
   //   uint256 beforeDeposit = token.balanceOf(address(this));
    //  token.safeTransferFrom(_msgSender(), address(this), quantity);
    //  uint256 afterDeposit = token.balanceOf(address(this));
    //  quantity = afterDeposit.sub(beforeDeposit);
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
  function vestCompletedSchedules(IERC20 token) public override returns (uint256) {
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
  function vestScheduleAtIndices(IERC20 token, uint256[] memory indexes)
    public 
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


  /* ========== VIEW FUNCTIONS ========== */

  /**
   * @notice The number of vesting dates in an account's schedule.
   */
  function numVestingSchedules(address account, IERC20 token)
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
    IERC20 token,
    uint256 index
  ) external override view returns (VestingSchedule memory) {
    return accountVestingSchedules[account][token].data[index];
  }

   function getVestingQuantityAtIndex(
    address account,
    IERC20 token,
    uint256 index
  ) public view returns (uint256) {
    VestingSchedule memory schedule = accountVestingSchedules[account][token].data[index];
    return _getVestingQuantity(schedule);
  }

  /**
   * @dev Get all schedules for an account.
   */
  function getVestingSchedules(address account, IERC20 token)
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

  function getRewardContractsPerToken(IERC20 token)
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

  function _completeVesting(IERC20 token, uint256 totalVesting) internal {
    require(totalVesting != 0, '0 vesting amount');
    accountEscrowedBalance[msg.sender][token] = accountEscrowedBalance[msg.sender][token].sub(
      totalVesting
    );
    accountVestedBalance[msg.sender][token] = accountVestedBalance[msg.sender][token].add(
      totalVesting
    );

    if (token == IERC20(0)) {
      (bool success, ) = msg.sender.call{value: totalVesting}('');
      require(success, 'fail to transfer');
    } else {
      token.safeTransfer(msg.sender, totalVesting);
    }
    emit Vest(token, totalVesting);
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

  function withdraw(IERC20 currency) external onlyOwner {
        currency.transfer(msg.sender,  currency.balanceOf(address(this)));
  }

  /**
   * @dev wrap block.number so we can easily mock it
   */
  function _blockNumber() internal virtual view returns (uint256) {
    return block.number;
  }

  /**
   * @dev Increase the max reward contract size
   */
  function updateMaxContractSize(uint256 _size) external onlyOwner {
      MAX_REWARD_CONTRACTS_SIZE = _size;
      emit UpdateMaxContractSize(_size);
  }
}
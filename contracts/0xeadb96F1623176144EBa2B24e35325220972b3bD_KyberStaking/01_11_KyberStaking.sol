// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {Math} from '@openzeppelin/contracts/math/Math.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/SafeCast.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {PermissionAdmin} from '@kyber.network/utils-sc/contracts/PermissionAdmin.sol';

import {IKyberStaking} from '../interfaces/staking/IKyberStaking.sol';
import {IWithdrawHandler} from '../interfaces/staking/IWithdrawHandler.sol';
import {EpochUtils} from '../misc/EpochUtils.sol';

/**
 * @notice   This contract is using SafeMath for uint, which is inherited from EpochUtils
 *           Some events are moved to interface, easier for public uses
 */
contract KyberStaking is IKyberStaking, EpochUtils, ReentrancyGuard, PermissionAdmin {
  using Math for uint256;
  using SafeMath for uint256;
  struct StakerData {
    uint128 stake;
    uint128 delegatedStake;
    address representative;
    // true/false: if data has been initialized at an epoch for a staker
    bool hasInited;
  }

  IERC20 public immutable override kncToken;

  IWithdrawHandler public withdrawHandler;
  // staker data per epoch, including stake, delegated stake and representative
  mapping(uint256 => mapping(address => StakerData)) internal stakerPerEpochData;
  // latest data of a staker, including stake, delegated stake, representative
  mapping(address => StakerData) internal stakerLatestData;

  // event is fired if something is wrong with withdrawal
  // even though the withdrawal is still successful
  event WithdrawDataUpdateFailed(uint256 curEpoch, address staker, uint256 amount);

  event UpdateWithdrawHandler(IWithdrawHandler withdrawHandler);

  constructor(
    address _admin,
    IERC20 _kncToken,
    uint256 _epochPeriod,
    uint256 _startTime
  ) PermissionAdmin(_admin) EpochUtils(_epochPeriod, _startTime) {
    require(_startTime >= block.timestamp, 'ctor: start in the past');

    require(_kncToken != IERC20(0), 'ctor: kncToken 0');
    kncToken = _kncToken;
  }

  function updateWithdrawHandler(IWithdrawHandler _withdrawHandler) external onlyAdmin {
    withdrawHandler = _withdrawHandler;

    emit UpdateWithdrawHandler(_withdrawHandler);
  }

  /**
   * @dev calls to set delegation for msg.sender, will take effect from the next epoch
   * @param newRepresentative address to delegate to
   */
  function delegate(address newRepresentative) external override {
    require(newRepresentative != address(0), 'delegate: representative 0');
    address staker = msg.sender;
    uint256 curEpoch = getCurrentEpochNumber();

    initDataIfNeeded(staker, curEpoch);

    address curRepresentative = stakerPerEpochData[curEpoch + 1][staker].representative;
    // nothing changes here
    if (newRepresentative == curRepresentative) {
      return;
    }

    uint256 updatedStake = stakerPerEpochData[curEpoch + 1][staker].stake;

    // reduce delegatedStake for curRepresentative if needed
    if (curRepresentative != staker) {
      initDataIfNeeded(curRepresentative, curEpoch);
      decreaseDelegatedStake(stakerPerEpochData[curEpoch + 1][curRepresentative], updatedStake);
      decreaseDelegatedStake(stakerLatestData[curRepresentative], updatedStake);

      emit Delegated(staker, curRepresentative, curEpoch, false);
    }

    stakerLatestData[staker].representative = newRepresentative;
    stakerPerEpochData[curEpoch + 1][staker].representative = newRepresentative;

    // ignore if staker is delegating back to himself
    if (newRepresentative != staker) {
      initDataIfNeeded(newRepresentative, curEpoch);
      increaseDelegatedStake(stakerPerEpochData[curEpoch + 1][newRepresentative], updatedStake);
      increaseDelegatedStake(stakerLatestData[newRepresentative], updatedStake);

      emit Delegated(staker, newRepresentative, curEpoch, true);
    }
  }

  /**
   * @dev call to stake more KNC for msg.sender
   * @param amount amount of KNC to stake
   */
  function deposit(uint256 amount) external override {
    require(amount > 0, 'deposit: amount is 0');

    uint256 curEpoch = getCurrentEpochNumber();
    address staker = msg.sender;

    // collect KNC token from staker
    require(kncToken.transferFrom(staker, address(this), amount), 'deposit: can not get token');

    initDataIfNeeded(staker, curEpoch);
    increaseStake(stakerPerEpochData[curEpoch + 1][staker], amount);
    increaseStake(stakerLatestData[staker], amount);

    // increase delegated stake for address that staker has delegated to (if it is not staker)
    address representative = stakerPerEpochData[curEpoch + 1][staker].representative;
    if (representative != staker) {
      initDataIfNeeded(representative, curEpoch);
      increaseDelegatedStake(stakerPerEpochData[curEpoch + 1][representative], amount);
      increaseDelegatedStake(stakerLatestData[representative], amount);
    }

    emit Deposited(curEpoch, staker, amount);
  }

  /**
   * @dev call to withdraw KNC from staking
   * @dev it could affect voting point when calling withdrawHandlers handleWithdrawal
   * @param amount amount of KNC to withdraw
   */
  function withdraw(uint256 amount) external override nonReentrant {
    require(amount > 0, 'withdraw: amount is 0');

    uint256 curEpoch = getCurrentEpochNumber();
    address staker = msg.sender;

    require(
      stakerLatestData[staker].stake >= amount,
      'withdraw: latest amount staked < withdrawal amount'
    );

    initDataIfNeeded(staker, curEpoch);
    decreaseStake(stakerLatestData[staker], amount);

    (bool success, ) = address(this).call(
      abi.encodeWithSelector(KyberStaking.handleWithdrawal.selector, staker, amount, curEpoch)
    );
    if (!success) {
      // Note: should catch this event to check if something went wrong
      emit WithdrawDataUpdateFailed(curEpoch, staker, amount);
    }

    // transfer KNC back to staker
    require(kncToken.transfer(staker, amount), 'withdraw: can not transfer knc');
    emit Withdraw(curEpoch, staker, amount);
  }

  /**
   * @dev initialize data if needed, then return staker's data for current epoch
   * @param staker - staker's address to initialize and get data for
   */
  function initAndReturnStakerDataForCurrentEpoch(address staker)
    external
    override
    nonReentrant
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    uint256 curEpoch = getCurrentEpochNumber();
    initDataIfNeeded(staker, curEpoch);

    StakerData memory stakerData = stakerPerEpochData[curEpoch][staker];
    stake = stakerData.stake;
    delegatedStake = stakerData.delegatedStake;
    representative = stakerData.representative;
  }

  /**
   * @notice return raw data of a staker for an epoch
   *         WARN: should be used only for initialized data
   *          if data has not been initialized, it will return all 0
   *          pool master shouldn't use this function to compute/distribute rewards of pool members
   */
  function getStakerRawData(address staker, uint256 epoch)
    external
    override
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    StakerData memory stakerData = stakerPerEpochData[epoch][staker];
    stake = stakerData.stake;
    delegatedStake = stakerData.delegatedStake;
    representative = stakerData.representative;
  }

  /**
   * @dev allow to get data up to current epoch + 1
   */
  function getStake(address staker, uint256 epoch) external view returns (uint256) {
    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return 0;
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        return stakerPerEpochData[i][staker].stake;
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    return 0;
  }

  /**
   * @dev allow to get data up to current epoch + 1
   */
  function getDelegatedStake(address staker, uint256 epoch) external view returns (uint256) {
    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return 0;
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        return stakerPerEpochData[i][staker].delegatedStake;
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    return 0;
  }

  /**
   * @dev allow to get data up to current epoch + 1
   */
  function getRepresentative(address staker, uint256 epoch) external view returns (address) {
    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return address(0);
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        return stakerPerEpochData[i][staker].representative;
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    // not delegated to anyone, default to yourself
    return staker;
  }

  /**
   * @notice return combine data (stake, delegatedStake, representative) of a staker
   * @dev allow to get staker data up to current epoch + 1
   */
  function getStakerData(address staker, uint256 epoch)
    external
    override
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    stake = 0;
    delegatedStake = 0;
    representative = address(0);

    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return (stake, delegatedStake, representative);
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        stake = stakerPerEpochData[i][staker].stake;
        delegatedStake = stakerPerEpochData[i][staker].delegatedStake;
        representative = stakerPerEpochData[i][staker].representative;
        return (stake, delegatedStake, representative);
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    // not delegated to anyone, default to yourself
    representative = staker;
  }

  function getLatestRepresentative(address staker) external view returns (address) {
    return
      stakerLatestData[staker].representative == address(0)
        ? staker
        : stakerLatestData[staker].representative;
  }

  function getLatestDelegatedStake(address staker) external view returns (uint256) {
    return stakerLatestData[staker].delegatedStake;
  }

  function getLatestStakeBalance(address staker) external view returns (uint256) {
    return stakerLatestData[staker].stake;
  }

  function getLatestStakerData(address staker)
    external
    override
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    stake = stakerLatestData[staker].stake;
    delegatedStake = stakerLatestData[staker].delegatedStake;
    representative = stakerLatestData[staker].representative == address(0)
      ? staker
      : stakerLatestData[staker].representative;
  }

  /**
    * @dev  separate logics from withdraw, so staker can withdraw as long as amount <= staker's deposit amount
            calling this function from withdraw function, ignore reverting
    * @param staker staker that is withdrawing
    * @param amount amount to withdraw
    * @param curEpoch current epoch
    */
  function handleWithdrawal(
    address staker,
    uint256 amount,
    uint256 curEpoch
  ) external {
    require(msg.sender == address(this), 'only staking contract');
    // update staker's data for next epoch
    decreaseStake(stakerPerEpochData[curEpoch + 1][staker], amount);
    address representative = stakerPerEpochData[curEpoch + 1][staker].representative;
    if (representative != staker) {
      initDataIfNeeded(representative, curEpoch);
      decreaseDelegatedStake(stakerPerEpochData[curEpoch + 1][representative], amount);
      decreaseDelegatedStake(stakerLatestData[representative], amount);
    }

    representative = stakerPerEpochData[curEpoch][staker].representative;
    uint256 curStake = stakerPerEpochData[curEpoch][staker].stake;
    uint256 lStakeBal = stakerLatestData[staker].stake;
    uint256 newStake = curStake.min(lStakeBal);
    uint256 reduceAmount = curStake.sub(newStake); // newStake is always <= curStake

    if (reduceAmount > 0) {
      if (representative != staker) {
        initDataIfNeeded(representative, curEpoch);
        // staker has delegated to representative, withdraw will affect representative's delegated stakes
        decreaseDelegatedStake(stakerPerEpochData[curEpoch][representative], reduceAmount);
      }
      stakerPerEpochData[curEpoch][staker].stake = SafeCast.toUint128(newStake);
      // call withdrawHandlers to reduce reward, if staker has delegated, then pass his representative
      if (withdrawHandler != IWithdrawHandler(0)) {
        (bool success, ) = address(withdrawHandler).call(
          abi.encodeWithSelector(
            IWithdrawHandler.handleWithdrawal.selector,
            representative,
            reduceAmount
          )
        );
        if (!success) {
          emit WithdrawDataUpdateFailed(curEpoch, staker, amount);
        }
      }
    }
  }

  /**
   * @dev initialize data if it has not been initialized yet
   * @param staker staker's address to initialize
   * @param epoch should be current epoch
   */
  function initDataIfNeeded(address staker, uint256 epoch) internal {
    address representative = stakerLatestData[staker].representative;
    if (representative == address(0)) {
      // not delegate to anyone, consider as delegate to yourself
      stakerLatestData[staker].representative = staker;
      representative = staker;
    }

    uint128 lStakeBal = stakerLatestData[staker].stake;
    uint128 ldStake = stakerLatestData[staker].delegatedStake;

    if (!stakerPerEpochData[epoch][staker].hasInited) {
      stakerPerEpochData[epoch][staker] = StakerData({
        stake: lStakeBal,
        delegatedStake: ldStake,
        representative: representative,
        hasInited: true
      });
    }

    // whenever stakers deposit/withdraw/delegate, the current and next epoch data need to be updated
    // as the result, we will also initialize data for staker at the next epoch
    if (!stakerPerEpochData[epoch + 1][staker].hasInited) {
      stakerPerEpochData[epoch + 1][staker] = StakerData({
        stake: lStakeBal,
        delegatedStake: ldStake,
        representative: representative,
        hasInited: true
      });
    }
  }

  function decreaseDelegatedStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.delegatedStake = SafeCast.toUint128(uint256(stakeData.delegatedStake).sub(amount));
  }

  function increaseDelegatedStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.delegatedStake = SafeCast.toUint128(uint256(stakeData.delegatedStake).add(amount));
  }

  function increaseStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.stake = SafeCast.toUint128(uint256(stakeData.stake).add(amount));
  }

  function decreaseStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.stake = SafeCast.toUint128(uint256(stakeData.stake).sub(amount));
  }
}
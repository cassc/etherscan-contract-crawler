// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/IAbstractMultiRewards.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev Based on: https://github.com/indexed-finance/dividends/blob/master/contracts/base/AbstractDividends.sol
 * Renamed dividends to rewards.
 * @dev (OLD) Many functions in this contract were taken from this repository:
 * https://github.com/atpar/funds-distribution-token/blob/master/contracts/FundsDistributionToken.sol
 * which is an example implementation of ERC 2222, the draft for which can be found at
 * https://github.com/atpar/funds-distribution-token/blob/master/EIP-DRAFT.md
 *
 * This contract has been substantially modified from the original and does not comply with ERC 2222.
 * Many functions were renamed as "rewards" rather than "funds" and the core functionality was separated
 * into this abstract contract which can be inherited by anything tracking ownership of reward shares.
 */
abstract contract AbstractMultiRewards is IAbstractMultiRewards {
  using SafeCast for uint128;
  using SafeCast for uint256;
  using SafeCast for int256;

/* ========  Constants  ======== */
  uint128 public constant POINTS_MULTIPLIER = type(uint128).max;

  event PointsCorrectionUpdated(address indexed reward, address indexed account, int256 points);

/* ========  Internal Function References  ======== */
  function(address) view returns (uint256) private immutable getSharesOf;
  function() view returns (uint256) private immutable getTotalShares;

/* ========  Storage  ======== */
  mapping(address => uint256) public pointsPerShare; //reward token address => points per share
  mapping(address => mapping(address => int256)) public pointsCorrection; //reward token address => mapping(user address => pointsCorrection)
  mapping(address => mapping(address => uint256)) public withdrawnRewards; //reward token address => mapping(user address => withdrawnRewards)

  constructor(
    function(address) view returns (uint256) getSharesOf_,
    function() view returns (uint256) getTotalShares_
  ) {
    getSharesOf = getSharesOf_;
    getTotalShares = getTotalShares_;
  }

/* ========  Public View Functions  ======== */
  /**
   * @dev Returns the total amount of rewards a given address is able to withdraw.
   * @param _reward Address of the reward token
   * @param _account Address of a reward recipient
   * @return A uint256 representing the rewards `account` can withdraw
   */
  function withdrawableRewardsOf(address _reward, address _account) public view override returns (uint256) {
    return cumulativeRewardsOf(_reward, _account) - withdrawnRewards[_reward][_account];
  }

  /**
   * @notice View the amount of rewards that an address has withdrawn.
   * @param _reward The address of the reward token.
   * @param _account The address of a token holder.
   * @return The amount of rewards that `account` has withdrawn.
   */
  function withdrawnRewardsOf(address _reward, address _account) public view override returns (uint256) {
    return withdrawnRewards[_reward][_account];
  }

  /**
   * @notice View the amount of rewards that an address has earned in total.
   * @dev accumulativeFundsOf(reward, account) = withdrawableRewardsOf(reward, account) + withdrawnRewardsOf(reward, account)
   * = (pointsPerShare[reward] * balanceOf(account) + pointsCorrection[reward][account]) / POINTS_MULTIPLIER
   * @param _reward The address of the reward token.
   * @param _account The address of a token holder.
   * @return The amount of rewards that `account` has earned in total.
   */
  function cumulativeRewardsOf(address _reward, address _account) public view override returns (uint256) {
    return ((pointsPerShare[_reward] * getSharesOf(_account)).toInt256() + pointsCorrection[_reward][_account]).toUint256() / POINTS_MULTIPLIER;
  }

/* ========  Dividend Utility Functions  ======== */

  /** 
   * @notice Distributes rewards to token holders.
   * @dev It reverts if the total shares is 0.
   * It emits the `RewardsDistributed` event if the amount to distribute is greater than 0.
   * About undistributed rewards:
   *   In each distribution, there is a small amount which does not get distributed,
   *   which is `(amount * POINTS_MULTIPLIER) % totalShares()`.
   *   With a well-chosen `POINTS_MULTIPLIER`, the amount of funds that are not getting
   *   distributed in a distribution can be less than 1 (base unit).
   */
  function _distributeRewards(address _reward, uint256 _amount) internal {
    require(_reward != address(0), "AbstractRewards._distributeRewards: reward cannot be zero address");

    uint256 shares = getTotalShares();
    require(shares > 0, "AbstractRewards._distributeRewards: total share supply is zero");

    if (_amount > 0) {
      pointsPerShare[_reward] = pointsPerShare[_reward] + (_amount * POINTS_MULTIPLIER / shares);
      emit RewardsDistributed(msg.sender, _reward,  _amount);
    }
  }

  /**
   * @notice Prepares collection of owed rewards
   * @dev It emits a `RewardsWithdrawn` event if the amount of withdrawn rewards is
   * greater than 0.
   */
  function _prepareCollect(address _reward, address _account) internal returns (uint256) {
    require(_reward != address(0), "AbstractRewards._prepareCollect: reward cannot be zero address");
    require(_account != address(0), "AbstractRewards._prepareCollect: account cannot be zero address");

    uint256 _withdrawableDividend = withdrawableRewardsOf(_reward, _account);
    if (_withdrawableDividend > 0) {
      withdrawnRewards[_reward][_account] = withdrawnRewards[_reward][_account] + _withdrawableDividend;
      emit RewardsWithdrawn(_reward, _account, _withdrawableDividend);
    }
    return _withdrawableDividend;
  }

  function _correctPointsForTransfer(address _reward, address _from, address _to, uint256 _shares) internal {
    require(_reward != address(0), "AbstractRewards._correctPointsForTransfer: reward address cannot be zero address");
    require(_from != address(0), "AbstractRewards._correctPointsForTransfer: from address cannot be zero address");
    require(_to != address(0), "AbstractRewards._correctPointsForTransfer: to address cannot be zero address");
    require(_shares != 0, "AbstractRewards._correctPointsForTransfer: shares cannot be zero");

    int256 _magCorrection = (pointsPerShare[_reward] * _shares).toInt256();
    pointsCorrection[_reward][_from] = pointsCorrection[_reward][_from] + _magCorrection;
    pointsCorrection[_reward][_to] = pointsCorrection[_reward][_to] - _magCorrection;

    emit PointsCorrectionUpdated(_reward, _from, pointsCorrection[_reward][_from]);
    emit PointsCorrectionUpdated(_reward, _to, pointsCorrection[_reward][_to]);
  }

  /**
   * @dev Increases or decreases the points correction for `account` by
   * `shares*pointsPerShare[reward]`.
   */
  function _correctPoints(address _reward, address _account, int256 _shares) internal {
    require(_reward != address(0), "AbstractRewards._correctPoints: reward cannot be zero address");
    require(_account != address(0), "AbstractRewards._correctPoints: account cannot be zero address");
    require(_shares != 0, "AbstractRewards._correctPoints: shares cannot be zero");

    pointsCorrection[_reward][_account] = pointsCorrection[_reward][_account] + (_shares * (pointsPerShare[_reward].toInt256()));
    emit PointsCorrectionUpdated(_reward, _account, pointsCorrection[_reward][_account]);
  }
}
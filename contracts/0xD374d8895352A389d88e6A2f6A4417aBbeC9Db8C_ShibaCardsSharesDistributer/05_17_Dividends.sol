// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract Dividends {
  using SafeMath for uint256;
  using SafeCast for uint128;
  using SafeCast for uint256;
  using SafeCast for int256;
  using SignedSafeMath for int256;

  /**
   * @dev This event emits when new funds are distributed
   * @param dividendsDistributed the amount of funds received for distribution
   */
  event DividendsDistributed(uint256 dividendsDistributed);

  /**
   * @dev This event emits when distributed funds are withdrawn by a token holder.
   * @param by the address of the receiver of funds
   * @param fundsWithdrawn the amount of funds that were withdrawn
   */
  event DividendsWithdrawn(address indexed by, uint256 fundsWithdrawn);

  /* ========  Constants  ======== */
  uint128 internal constant POINTS_MULTIPLIER = type(uint128).max;

  /* ========  Virtual methods, must be implemented  ======== */
  function getSharesOf(address) public view virtual returns (uint256);

  function getTotalShares() public view virtual returns (uint256);

  /* ========  Storage  ======== */
  uint256 public pointsPerShare;
  mapping(address => int256) internal pointsCorrection;
  mapping(address => uint256) private withdrawnDividends;

  /* ========  Public View Functions  ======== */
  /**
   * @dev Returns the total amount of dividends a given address is able to withdraw.
   * @param account Address of a dividend recipient
   * @return A uint256 representing the dividends `account` can withdraw
   */
  function _withdrawableDividendsOf(address account)
    internal
    view
    returns (uint256)
  {
    return cumulativeDividendsOf(account).sub(withdrawnDividends[account]);
  }

  /**
   * @notice View the amount of dividends that an address has withdrawn.
   * @param account The address of a token holder.
   * @return The amount of dividends that `account` has withdrawn.
   */
  function _withdrawnDividendsOf(address account)
    internal
    view
    returns (uint256)
  {
    return withdrawnDividends[account];
  }

  /**
   * @notice View the amount of dividends that an address has earned in total.
   * @dev accumulativeFundsOf(account) = withdrawableDividendsOf(account) + withdrawnDividendsOf(account)
   * = (pointsPerShare * balanceOf(account) + pointsCorrection[account]) / POINTS_MULTIPLIER
   * @param account The address of a token holder.
   * @return The amount of dividends that `account` has earned in total.
   */
  function cumulativeDividendsOf(address account)
    public
    view
    returns (uint256)
  {
    return
      pointsPerShare
        .mul(getSharesOf(account))
        .toInt256()
        .add(pointsCorrection[account])
        .toUint256() / POINTS_MULTIPLIER;
  }

  /* ========  Dividend Utility Functions  ======== */

  /**
   * @notice Distributes dividends to token holders.
   * @dev It reverts if the total supply is 0.
   * It emits the `FundsDistributed` event if the amount to distribute is greater than 0.
   * About undistributed dividends:
   *   In each distribution, there is a small amount which does not get distributed,
   *   which is `(amount * POINTS_MULTIPLIER) % totalShares()`.
   *   With a well-chosen `POINTS_MULTIPLIER`, the amount of funds that are not getting
   *   distributed in a distribution can be less than 1 (base unit).
   */
  function _distributeDividends(uint256 amount) internal {
    uint256 shares = getTotalShares();
    if (amount > 0 && shares > 0) {
      pointsPerShare = pointsPerShare.add(
        amount.mul(POINTS_MULTIPLIER) / shares
      );
      emit DividendsDistributed(amount);
    }
  }

  /**
   * @notice Prepares collection of owed dividends
   * @dev It emits a `DividendsWithdrawn` event if the amount of withdrawn dividends is
   * greater than 0.
   */
  function _prepareCollect(address account) internal returns (uint256) {
    uint256 _withdrawableDividend = _withdrawableDividendsOf(account);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[account] = withdrawnDividends[account].add(
        _withdrawableDividend
      );
      emit DividendsWithdrawn(account, _withdrawableDividend);
    }
    return _withdrawableDividend;
  }

  function _correctPointsForTransfer(
    address from,
    address to,
    uint256 shares
  ) internal {
    int256 _magCorrection = pointsPerShare.mul(shares).toInt256();
    pointsCorrection[from] = pointsCorrection[from].add(_magCorrection);
    pointsCorrection[to] = pointsCorrection[to].sub(_magCorrection);
  }

  /**
   * @dev Increases or decreases the points correction for `account` by
   * `shares*pointsPerShare`.
   */
  function _correctPoints(address account, int256 shares) internal {
    pointsCorrection[account] = pointsCorrection[account].add(
      shares.mul(int256(pointsPerShare))
    );
  }
}
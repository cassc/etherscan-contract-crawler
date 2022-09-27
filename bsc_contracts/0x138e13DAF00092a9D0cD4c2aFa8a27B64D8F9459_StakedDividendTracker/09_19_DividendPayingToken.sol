// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../lib/SafeMathUint.sol";
import "../lib/SafeMathInt.sol";
import "../interfaces/DividendPayingTokenInterface.sol";
import "../interfaces/DividendPayingTokenOptionalInterface.sol";

abstract contract DividendPayingToken {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  mapping(uint=>uint) public balanceTb;

  uint public totalBalance; 

  event DividendsDistributed(address sender, uint amount);

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceTb(_user)`.
  // When `balanceTb(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceTb(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceTb(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceTb(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceTb(_user)) - (new balanceTb(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceTb(_user)` is changed.
  mapping(uint256 => int256) internal magnifiedDividendCorrections;
  mapping(uint256 => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalBalance`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function _distributeDividends(uint256 amount) internal {
      require(totalBalance > 0);

      if (amount > 0) {
          magnifiedDividendPerShare = magnifiedDividendPerShare.add(
              (amount).mul(magnitude) / totalBalance
          );
          emit DividendsDistributed(msg.sender, amount);

          totalDividendsDistributed = totalDividendsDistributed.add(amount);
      }
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param tokenId The address of a token holder.
  /// @return The amount of dividend in wei that `tokenId` can withdraw.
  function withdrawableDividendOf(uint tokenId) public view  returns(uint256) {
    return accumulativeDividendOf(tokenId).sub(withdrawnDividends[tokenId]);
  }

  /// @notice View the amount of dividend in wei that an tokenId has withdrawn.
  /// @param tokenId token id.
  /// @return The amount of dividend in wei that `tokenId` has withdrawn.
  function withdrawnDividendOf(uint tokenId) public view returns(uint256) {
    return withdrawnDividends[tokenId];
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(tokenId) = withdrawableDividendOf(tokenId) + withdrawnDividendOf(tokenId)
  /// @param tokenId token id.
  /// = (magnifiedDividendPerShare * balanceTb(tokenId) + magnifiedDividendCorrections[tokenId]) / magnitude
  /// @return The amount of dividend in wei that `tokenId` has earned in total.
  function accumulativeDividendOf(uint tokenId) public view returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceTb[tokenId]).toInt256Safe()
      .add(magnifiedDividendCorrections[tokenId]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param tokenId token id
  /// @param value The amount that will be created.
  function _mint(uint256 tokenId, uint256 value) internal  {
    totalBalance += value;
    balanceTb[tokenId] += value;

    magnifiedDividendCorrections[tokenId] = magnifiedDividendCorrections[tokenId]
      .sub((magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param tokenId token id
  /// @param value The amount that will be burnt.
  function _burn(uint256 tokenId, uint256 value) internal {
    totalBalance -= value;
    balanceTb[tokenId] -= value;

    magnifiedDividendCorrections[tokenId] = magnifiedDividendCorrections[tokenId]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(uint256 tokenId, uint256 newBalance) internal {
    uint256 currentBalance = balanceTb[tokenId];

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(tokenId, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(tokenId, burnAmount);
    }
  }
}
// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {
  IStakingRewards, StakedPosition, StakedPositionType
} from "crate/interfaces/IStakingRewards.sol";
import {IFiduLense} from "crate/interfaces/IFiduLense.sol";
import {ISeniorPool} from "crate/interfaces/ISeniorPool.sol";
import {FiduConversion} from "crate/library/FiduConversion.sol";

/**
 * @title FiduLense
 * @author Warbler Labs Engineering
 * @notice A contract responsible for valuing a given address's FIDU holdings
 *          using the current senior pool share price. This contract inspects the fidu
 *          held at the given address as well as the value of their staked FIDU. It
 *          _does not_ account for FIDU being used to LP in secondary markets.
 */
contract FiduLense is IFiduLense {
  IERC20 public immutable fidu;
  IStakingRewards public immutable stakingRewards;
  ISeniorPool public immutable seniorPool;

  constructor(IERC20 _fidu, IStakingRewards _stakingRewards, ISeniorPool _seniorPool) {
    fidu = _fidu;
    stakingRewards = _stakingRewards;
    seniorPool = _seniorPool;
  }

  /// @inheritdoc IFiduLense
  function fiduPositionValue(address addr) external view returns (uint256) {
    uint256 fiduPositionSize = _totalFiduBalanceOf(addr);
    return fiduToUsdc(fiduPositionSize);
  }

  /// @inheritdoc IFiduLense
  function usdcToFidu(uint256 usdcAmount) external view returns (uint256) {
    uint256 sharePrice = seniorPool.sharePrice();
    uint256 fiduAmount = FiduConversion.usdcToFidu(usdcAmount, sharePrice);
    return fiduAmount;
  }

  /// @inheritdoc IFiduLense
  function fiduToUsdc(uint256 fiduAmount) public view returns (uint256) {
    uint256 sharePrice = seniorPool.sharePrice();
    uint256 usdcAmount = FiduConversion.fiduToUsdc(fiduAmount, sharePrice);
    return usdcAmount;
  }

  function _totalFiduBalanceOf(address addr) private view returns (uint256) {
    return _fiduBalanceOf(addr) + _stakedFiduBalanceOf(addr);
  }

  function _fiduBalanceOf(address addr) private view returns (uint256) {
    return fidu.balanceOf(addr);
  }

  function _stakedFiduBalanceOf(address addr) private view returns (uint256) {
    uint256 nTokens = stakingRewards.balanceOf(addr);
    uint256 totalFidu;
    for (uint256 i = 0; i < nTokens; i++) {
      uint256 currentTokenId = stakingRewards.tokenOfOwnerByIndex(addr, i);

      StakedPosition memory position = stakingRewards.getPosition(currentTokenId);
      StakedPositionType positionType = position.positionType;

      if (positionType == StakedPositionType.Fidu) {
        totalFidu += position.amount;
      }
    }

    return totalFidu;
  }
}
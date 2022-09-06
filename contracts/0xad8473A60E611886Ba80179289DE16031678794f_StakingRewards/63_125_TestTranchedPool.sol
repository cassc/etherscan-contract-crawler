// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";
import {TranchedPool} from "../protocol/core/TranchedPool.sol";
import {TranchingLogic} from "../protocol/core/TranchingLogic.sol";

contract TestTranchedPool is TranchedPool {
  function collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) public {
    _collectInterestAndPrincipal(from, interest, principal);
  }

  function _setSeniorTranchePrincipalDeposited(uint256 principalDeposited) public {
    _poolSlices[numSlices - 1].seniorTranche.principalDeposited = principalDeposited;
  }

  /**
   * @notice Converts USDC amounts to share price
   * @param amount The USDC amount to convert
   * @param totalShares The total shares outstanding
   * @return The share price of the input amount
   */
  function usdcToSharePrice(uint256 amount, uint256 totalShares) public pure returns (uint256) {
    return TranchingLogic.usdcToSharePrice(amount, totalShares);
  }

  /**
   * @notice Converts share price to USDC amounts
   * @param sharePrice The share price to convert
   * @param totalShares The total shares outstanding
   * @return The USDC amount of the input share price
   */
  function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares) public pure returns (uint256) {
    return TranchingLogic.sharePriceToUsdc(sharePrice, totalShares);
  }

  function _setLimit(uint256 limit) public {
    creditLine.setLimit(limit);
  }

  function _modifyJuniorTrancheLockedUntil(uint256 lockedUntil) public {
    _poolSlices[numSlices - 1].juniorTranche.lockedUntil = lockedUntil;
  }
}
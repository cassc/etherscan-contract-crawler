// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IIdleCDOStrategy.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IIdleCDOTrancheRewards.sol";
import "./interfaces/IStakedAave.sol";
import "./strategies/truefi/IdleTruefiStrategy.sol";

import "./IdleCDO.sol";
import {ITruefiPool, ITrueLender, ILoanToken} from "./interfaces/truefi/ITruefi.sol";

error Default();
error Is0();

/// @title IdleCDO variant for TrueFi. 
/// @author Idle Labs Inc.
/// @dev In this variant the `_checkDefault` is perfomed by looping through all loans (which should always be at most like 10-20)
/// and checking if any loan is defaulted. The _withdraw is also handled differently because of their exit fee penalty.
contract IdleCDOTruefiVariant is IdleCDO {
  using SafeERC20Upgradeable for IERC20Detailed;

  /// @dev check if any loan for the pool is defaulted
  function _checkDefault() override internal view {
    // loop thorugh all loans, which should be at most like 10-20
    // and see if any loan is defaulted
    ITruefiPool _truePool = IdleTruefiStrategy(strategy)._pool();
    ILoanToken[] memory loans = _truePool.lender().loans(_truePool);
    for (uint256 i = 0; i < loans.length; i++) {
      if (ILoanToken(loans[i]).status() == ILoanToken.Status.Defaulted) {
        revert Default();
      }
    }
  }

  /// @notice It allows users to burn their tranche token and redeem their principal + interest back
  /// @dev automatically reverts on lending provider default (_strategyPrice decreased).
  /// @param _amount in tranche tokens
  /// @param _tranche tranche address
  /// @return toRedeem number of underlyings redeemed
  function _withdraw(uint256 _amount, address _tranche) override internal nonReentrant returns (uint256 toRedeem) {
    // check if a deposit is made in the same block from the same user
    _checkSameTx();
    // check if _strategyPrice decreased
    _checkDefault();
    // accrue interest to tranches and updates tranche prices
    _updateAccounting();
    // redeem all user balance if 0 is passed as _amount
    if (_amount == 0) {
      _amount = IERC20Detailed(_tranche).balanceOf(msg.sender);
    }
    if (_amount == 0) {
      revert Is0();
    }

    address _token = token;
    address _aa = AATranche;
    IdleCDOTranche _selectedTranche = IdleCDOTranche(_tranche);
    uint256 _strategyTokens = IERC20Detailed(strategyToken).totalSupply();
    // round down for BB tranche
    uint256 _strategyTokensBB = _strategyTokens * (FULL_ALLOC - _getAARatio(true)) / FULL_ALLOC;
    uint256 _strategyTokensForTranche = _aa == _tranche ? _strategyTokens - _strategyTokensBB : _strategyTokensBB;

    toRedeem = IIdleCDOStrategy(strategy).redeem(
      // strategyToken amount = strategyTokensForAA * trancheamount / trancheSupply
      _strategyTokensForTranche * _amount / _selectedTranche.totalSupply()
    );
    // burn tranche token
    _selectedTranche.burn(msg.sender, _amount);
    // send underlying to msg.sender
    IERC20Detailed(_token).safeTransfer(msg.sender, toRedeem);
    // update NAV with the _amount of underlyings removed
    if (_tranche == _aa) {
      lastNAVAA -= toRedeem;
    } else {
      lastNAVBB -= toRedeem;
    }

    // update trancheAPRSplitRatio
    _updateSplitRatio();
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LibStarVault} from '../libraries/LibStarVault.sol';
import {Errors} from '../libraries/Errors.sol';
import {IStarVault} from '../interfaces/IStarVault.sol';

/**
 * The StarVault estimates, collects, and tracks fees for partners
 */
contract StarVault is IStarVault {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  error InsufficientOwnerBalance(uint256 available);

  function partnerTokens(address partner) external view returns (address[] memory tokens_) {
    LibStarVault.State storage s = LibStarVault.state();

    EnumerableSet.AddressSet storage tokenSet = s.partnerTokens[partner];
    uint256 length = tokenSet.length();

    tokens_ = new address[](length);

    for (uint256 tokenIndex; tokenIndex < length; tokenIndex++) {
      tokens_[tokenIndex] = tokenSet.at(tokenIndex);
    }
  }

  function partnerTokenBalance(address partner, address token) external view returns (uint256) {
    LibStarVault.State storage s = LibStarVault.state();

    return s.partnerBalances[partner][token];
  }

  function partnerWithdraw(address token) external {
    LibStarVault.State storage s = LibStarVault.state();

    uint256 balance = s.partnerBalances[msg.sender][token];

    if (balance > 0) {
      s.partnerBalances[msg.sender][token] = 0;
      s.partnerBalancesTotal[token] -= balance;

      emit PartnerWithdraw(msg.sender, token, balance);

      if (token == address(0)) {
        // NOTE: Control transfered to untrusted address
        (bool sent, ) = payable(msg.sender).call{value: balance}('');

        if (!sent) {
          revert Errors.EthTransferFailed();
        }
      } else {
        // NOTE: The token is not removed from the partner's token set
        IERC20(token).safeTransfer(msg.sender, balance);
      }
    }
  }

  function ownerWithdraw(address token, uint256 amount, address payable to) external {
    LibDiamond.enforceIsContractOwner();

    LibStarVault.State storage s = LibStarVault.state();

    uint256 partnerBalanceTotal = s.partnerBalancesTotal[token];

    uint256 balance = token == address(0)
      ? address(this).balance
      : IERC20(token).balanceOf(address(this));

    uint256 available = balance - partnerBalanceTotal;

    if (amount > available) {
      revert InsufficientOwnerBalance(available);
    }

    if (token == address(0)) {
      // Send ETH
      (bool sent, ) = to.call{value: amount}('');

      if (!sent) {
        revert Errors.EthTransferFailed();
      }
    } else {
      IERC20(token).safeTransfer(to, amount);
    }
  }
}
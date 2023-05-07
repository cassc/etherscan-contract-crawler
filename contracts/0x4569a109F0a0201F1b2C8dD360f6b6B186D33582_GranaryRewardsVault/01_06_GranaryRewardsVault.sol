// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from './interfaces/IERC20.sol';
import {ILendingPoolAddressesProvider} from './interfaces/ILendingPoolAddressesProvider.sol';
import {Ownable} from './lib/Ownable.sol';
import {Errors} from './lib/Errors.sol';

contract GranaryRewardsVault is Ownable {
  ILendingPoolAddressesProvider public ADDRESSES_PROVIDER;
  address public INCENTIVES_CONTROLLER;
  address public REWARD_TOKEN;

  modifier onlyPoolAdmin {
    require(ADDRESSES_PROVIDER.getPoolAdmin() == _msgSender(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  constructor (
    address incentivesController,
    ILendingPoolAddressesProvider provider,
    address rewardToken
  ) public {
    INCENTIVES_CONTROLLER = incentivesController;
    ADDRESSES_PROVIDER = provider;
    REWARD_TOKEN = rewardToken;
  }

  function approveIncentivesController(uint256 value) external onlyPoolAdmin {
    IERC20(REWARD_TOKEN).approve(INCENTIVES_CONTROLLER, value);
  }

  function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
    (bool success, ) = to.call{value: amount}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  function emergencyTokenTransfer(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).transfer(to, amount);
  }
}
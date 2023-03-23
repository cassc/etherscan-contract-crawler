// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

import "../lib/CurrencyTransferLib.sol";
import "../interfaces/IWETH.sol";
import "./AaveStakingPool.sol";

contract AaveEthStakingPool is AaveStakingPool {
  using SafeMath for uint256;

  IWETH public weth;
 
  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _aavePool,
    address _aToken,
    address _rewardsToken,
    address _weth,
    uint256 _durationInDays
  ) AaveStakingPool(_aavePool, _aToken, _rewardsToken, _weth, _durationInDays) {
    weth = IWETH(_weth);
  }

  function _transferStakingToken(uint256 amount) override internal virtual {
    require(msg.value >= amount, 'Not enough value');
    weth.deposit{value: amount}();
    
    // Return excessive ether
    uint256 diff = msg.value.sub(amount);
    if (diff > 0) {
      CurrencyTransferLib.transferCurrency(CurrencyTransferLib.NATIVE_TOKEN, address(this), msg.sender, diff);
    }

    // Auto deposit user staking to AAVE
    stakingToken.approve(address(aavePool), amount);
    aavePool.supply(address(stakingToken), amount, address(this), 0);
  }

  function _withdrawStakingToken(uint256 amount) override internal virtual {
    // Withdraw WETH from AAVE first
    aavePool.withdraw(address(stakingToken), amount, address(this));

    // Unwrap WETH to ETH
    weth.withdraw(amount);
    // Transfer ETH to user
    CurrencyTransferLib.transferCurrency(CurrencyTransferLib.NATIVE_TOKEN, address(this), msg.sender, amount);
  }

  function withdrawAdminRewards(address to) external override virtual nonReentrant onlyOwner {
    uint256 balance = aToken.balanceOf(address(this));
    uint256 amount = balance - _totalSupply;
    if (amount > 0) {
      aavePool.withdraw(address(weth), amount, address(this));
      weth.withdraw(amount);
      CurrencyTransferLib.transferCurrency(CurrencyTransferLib.NATIVE_TOKEN, address(this), to, amount);
      emit AdminRewardWithdrawn(to, amount);
    }
  }

}
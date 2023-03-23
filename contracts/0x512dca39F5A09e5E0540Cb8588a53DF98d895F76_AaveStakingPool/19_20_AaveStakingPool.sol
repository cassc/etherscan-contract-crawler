// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IAToken} from "@aave/core-v3/contracts/interfaces/IAToken.sol";

import "./StakingPoolV2.sol";

contract AaveStakingPool is StakingPoolV2 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IPool public aavePool;
  IAToken public aToken;
 
  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _aavePool,
    address _aToken,
    address _rewardsToken,
    address _stakingToken,
    uint256 _durationInDays
  ) StakingPoolV2(_rewardsToken, _stakingToken, _durationInDays) {
    aavePool = IPool(_aavePool);
    aToken = IAToken(_aToken);
  }

  function _transferStakingToken(uint256 amount) override internal virtual {
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);

    // Auto deposit user staking to AAVE
    stakingToken.approve(address(aavePool), amount);
    aavePool.supply(address(stakingToken), amount, address(this), 0);
  }

  function _withdrawStakingToken(uint256 amount) override internal virtual {
    // Withdraw from AAVE first
    aavePool.withdraw(address(stakingToken), amount, address(this));

    stakingToken.safeTransfer(msg.sender, amount);
  }

  function adminRewards() external override virtual view returns (uint256) {
    uint256 balance = aToken.balanceOf(address(this));
    require(balance >= _totalSupply, 'No admin rewards');
    return balance - _totalSupply;
  }

  function withdrawAdminRewards(address to) external override virtual nonReentrant onlyOwner {
    uint256 balance = aToken.balanceOf(address(this));
    uint256 amount = balance - _totalSupply;
    if (amount > 0) {
      aavePool.withdraw(address(stakingToken), amount, to);
      emit AdminRewardWithdrawn(to, amount);
    }
  }

}
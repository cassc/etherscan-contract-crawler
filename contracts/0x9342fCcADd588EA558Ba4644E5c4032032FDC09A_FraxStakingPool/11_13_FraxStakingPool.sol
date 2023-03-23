// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IsfrxETH.sol";
import "./StakingPoolV2.sol";

contract FraxStakingPool is StakingPoolV2 {
  using Math for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IsfrxETH public sfrxETH;
 
  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _sfrxETH,
    address _rewardsToken,
    address _frxETH,
    uint256 _durationInDays
  ) StakingPoolV2(_rewardsToken, _frxETH, _durationInDays) {
    sfrxETH = IsfrxETH(_sfrxETH);
  }

  function _transferStakingToken(uint256 amount) override internal virtual {
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);

    // Audo deposit frxETH to frax for rewards
    stakingToken.approve(address(sfrxETH), amount);
    sfrxETH.deposit(amount, address(this));
  }

  function _withdrawStakingToken(uint256 amount) override internal virtual {
    // Withdraw sfrxETH from frax first
    sfrxETH.withdraw(amount, address(this), address(this));

    stakingToken.safeTransfer(msg.sender, amount);
  }

  function adminRewards() external override virtual view returns (uint256) {
    uint256 sfrxETHAmount = sfrxETH.balanceOf(address(this));
    uint256 frxETHAmount = sfrxETHAmount.mulDiv(sfrxETH.pricePerShare(), 1e18, Math.Rounding.Down);
    require(frxETHAmount >= _totalSupply, 'No admin rewards');
    return frxETHAmount - _totalSupply;
  }

  function withdrawAdminRewards(address to) external override virtual nonReentrant onlyOwner {
    uint256 sfrxETHAmount = sfrxETH.balanceOf(address(this));
    uint256 frxETHAmount = sfrxETHAmount.mulDiv(sfrxETH.pricePerShare(), 1e18, Math.Rounding.Down);
    if (frxETHAmount > _totalSupply) {
      uint256 _adminRewards = frxETHAmount.sub(_totalSupply);
      sfrxETH.withdraw(_adminRewards, address(this), address(this));
      stakingToken.safeTransfer(to, _adminRewards);
      emit AdminRewardWithdrawn(to, _adminRewards);
    }
  }

}
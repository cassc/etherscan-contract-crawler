// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./Staking.sol";

contract CurrencyStaking is Staking {

  IERC20Upgradeable public currency;

  mapping(address => uint256) public stakedCurrencies;

  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);

  function initialize(Village _village, address currencyAddress) virtual public initializer {
    super.initialize(_village);
    currency = IERC20Upgradeable(currencyAddress);
  }

  function stake(uint amount) virtual assertStakesLand(tx.origin) public returns (uint finishTimestamp) {
    uint256 currentStakeId = currentStake[tx.origin];
    if (stakes[currentStakeId + 1].amount != 0) {
      require(stakedCurrencies[tx.origin] + amount == stakes[currentStakeId + 1].amount, 'You need to stake required currency amount');
    }
    if (currentStakeId == 0) {
      firstStake();
    } else {
      if (!currentStakeRewardClaimed[tx.origin]) {
        completeStake();
      }
      assignNextStake(currentStakeId);
    }
    currentStakeStart[tx.origin] = block.timestamp;
    currency.transferFrom(tx.origin, address(this), amount);
    stakedCurrencies[tx.origin] = stakedCurrencies[tx.origin] + amount;
    emit Staked(tx.origin, amount);
    return currentStakeStart[tx.origin] + stakes[currentStake[tx.origin]].duration;
  }

  function unstake() virtual public returns (bool stakeCompleted) {
    require(currentStake[tx.origin] != 0, 'You have no stakes to unstake');
    if (canCompleteStake()) {
      completeStake();
      stakeCompleted = true;
    }
    currentStake[tx.origin] = 0;
    currentStakeStart[tx.origin] = 0;
    currency.transfer(tx.origin, stakedCurrencies[tx.origin]);
    emit Unstaked(tx.origin, stakedCurrencies[tx.origin]);
    stakedCurrencies[tx.origin] = 0;
  }

  // VIEWS

  function getRequiredStakeAmount() external view returns (uint256) {
    if(stakes[currentStake[tx.origin] + 1].amount != 0) {
      return stakes[currentStake[tx.origin] + 1].amount - stakedCurrencies[tx.origin];
    } else {
      return 0;
    }
  }

  // SETTERS

  function setCurrency(address currencyAddress) external restricted {
    currency = IERC20Upgradeable(currencyAddress);
  }

}
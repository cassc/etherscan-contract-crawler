// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import "../lib/CurrencyTransferLib.sol";
import './StakingPool.sol';
import './EthStakingPool.sol';

contract StakingPoolFactory is Ownable {
  using SafeMath for uint256;

  // immutables
  address public rewardsToken;
  address public nativeTokenWrapper;

  // the staking tokens for which the rewards contract has been deployed
  address[] public stakingTokens;

  // info about rewards for a particular staking token
  struct StakingPoolInfo {
    address poolAddress;
    uint256 startTime;
    uint256 roundDurationInDays;
    uint256 totalRewardsAmount;
  }

  // rewards info by staking token
  mapping(address => StakingPoolInfo) public stakingPoolInfoByStakingToken;

  event StakingPoolDeployed(
    address indexed poolAddress,
    address indexed stakingToken,
    uint256 startTime,
    uint256 roundDurationInDays
  );

  constructor(
    address _rewardsToken,
    address _nativeTokenWrapper
  ) Ownable() {
    rewardsToken = _rewardsToken;
    nativeTokenWrapper = _nativeTokenWrapper;
  }

  function getStakingPoolAddress(address stakingToken) public virtual view returns (address) {
    StakingPoolInfo storage info = stakingPoolInfoByStakingToken[stakingToken];
    require(info.poolAddress != address(0), 'StakingPoolFactory::getPoolAddress: not deployed');
    return info.poolAddress;
  }

  function getStakingTokens() public virtual view returns (address[] memory) {
    return stakingTokens;
  }

  ///// permissioned functions

  // deploy a by-stages staking reward contract for the staking token
  function deployPool(address stakingToken, uint256 startTime, uint256 roundDurationInDays) public onlyOwner {
    StakingPoolInfo storage info = stakingPoolInfoByStakingToken[stakingToken];

    require(info.poolAddress == address(0), 'StakingPoolFactory::deployPool: already deployed');
    require(startTime >= block.timestamp, 'StakingPoolFactory::deployPool: start too soon');
    require(roundDurationInDays > 0, 'StakingPoolFactory::deployPool: duration too short');

    if (stakingToken == CurrencyTransferLib.NATIVE_TOKEN) {
      info.poolAddress = address(new EthStakingPool(/*_rewardsDistribution=*/ address(this), rewardsToken, nativeTokenWrapper, roundDurationInDays));
    } else {
      info.poolAddress = address(new StakingPool(/*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken, roundDurationInDays));
    }
    info.startTime = startTime;
    info.roundDurationInDays = roundDurationInDays;
    info.totalRewardsAmount = 0;

    stakingTokens.push(stakingToken);
    emit StakingPoolDeployed(info.poolAddress, stakingToken, startTime, roundDurationInDays);
  }

  // withdraw EL staking rewards from a staking pool after period finish.
  // this is only intended for rebasable staking tokens like stETH
  function withdrawELRewards(address stakingToken, address to) external onlyOwner {
    StakingPoolInfo storage info = stakingPoolInfoByStakingToken[stakingToken];
    require(info.poolAddress != address(0), 'StakingPoolFactory::withdrawELRewards: not deployed');
    require(block.timestamp >= info.startTime, 'StakingPoolFactory::withdrawELRewards: not ready');

    StakingPool(payable(address(info.poolAddress))).withdrawELRewards(to);
  }

  function addRewards(address stakingToken, uint256 rewardsAmount) public onlyOwner {
    StakingPoolInfo storage info = stakingPoolInfoByStakingToken[stakingToken];
    require(info.poolAddress != address(0), 'StakingPoolFactory::addRewards: not deployed');
    require(block.timestamp >= info.startTime, 'StakingPoolFactory::addRewards: not ready');

    if (rewardsAmount > 0) {
      info.totalRewardsAmount = info.totalRewardsAmount.add(rewardsAmount);

      require(
        IERC20(rewardsToken).transferFrom(msg.sender, info.poolAddress, rewardsAmount),
        'StakingPoolFactory::addRewards: transfer failed'
      );
      StakingPool(payable(address(info.poolAddress))).notifyRewardAmount(rewardsAmount);
    }
  }

}
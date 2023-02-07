pragma solidity ^0.6.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './StakingRewards.sol';

contract StakingRewardsFactory is Ownable {
    // immutables
    uint public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    address public lotteryContract;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint candyAmount;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(
        uint _stakingRewardsGenesis,
        address _lotteryContract
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'StakingRewardsFactory::constructor: genesis too soon');

        stakingRewardsGenesis = _stakingRewardsGenesis;
        lotteryContract = _lotteryContract;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward lottery tickets will be distributed to the staking reward contract no sooner than the genesis
    function deploy(address stakingToken, uint256 candyAmount) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), 'StakingRewardsFactory::deploy: already deployed');

        info.stakingRewards = address(new StakingRewards(/*_rewardsDistribution=*/ address(this), stakingToken, lotteryContract, owner()));
        info.candyAmount = candyAmount;
        stakingTokens.push(stakingToken);
    }

    ///// permissionless functions

    // call notifycandyAmounts for all staking tokens.
    function notifyCandyAmounts() public {
        require(stakingTokens.length > 0, 'StakingRewardsFactory::notifyCandyAmounts: called before any deploys');
        for (uint i = 0; i < stakingTokens.length; i++) {
            notifyCandyAmount(stakingTokens[i]);
        }
    }

    // notify lottery tickets amount for an individual staking token.
    // this is a fallback in case the notifyCandyAmounts costs too much gas to call for all contracts
    function notifyCandyAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::notifyCandyAmount: not ready');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyCandyAmount: not deployed');

        if (info.candyAmount > 0) {
            uint candyAmount = info.candyAmount;
            info.candyAmount = 0;

            /*require(
                IERC20(rewardsToken).transfer(info.stakingRewards, candyAmount),
                'StakingRewardsFactory::notifyCandyAmount: transfer failed'
            );*/
            StakingRewards(info.stakingRewards).notifyCandyAmount(candyAmount);
        }
    }
}
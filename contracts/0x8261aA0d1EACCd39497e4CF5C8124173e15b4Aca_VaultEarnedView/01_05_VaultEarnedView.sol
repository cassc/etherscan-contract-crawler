// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IConvexWrapperV2.sol";
import "./interfaces/IFraxFarmERC20.sol";
import "./interfaces/IRewards.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract VaultEarnedView{    

    constructor() {
    }

    //helper function to combine earned tokens on staking contract and any tokens that are on this vault
    function earned(address _stakingAddress, address _wrapper, address _extrarewards, address _vault) external returns (address[] memory token_addresses, uint256[] memory total_earned) {
        //simulate claim on wrapper
        IConvexWrapperV2(_wrapper).getReward(_vault);

        //get list of reward tokens
        address[] memory rewardTokens = IFraxFarmERC20(_stakingAddress).getAllRewardTokens();
        uint256[] memory stakedearned = IFraxFarmERC20(_stakingAddress).earned(_vault);
        uint256 convexrewardCnt = IConvexWrapperV2(_wrapper).rewardLength();


        uint256 extraRewardsLength;
        if(_extrarewards != address(0)){
            extraRewardsLength = IRewards(_extrarewards).rewardTokenLength();
        }

        token_addresses = new address[](rewardTokens.length + extraRewardsLength + convexrewardCnt);
        total_earned = new uint256[](rewardTokens.length + extraRewardsLength + convexrewardCnt);

        //add any tokens that happen to be already claimed but sitting on the vault
        //(ex. withdraw claiming rewards)
        for(uint256 i = 0; i < rewardTokens.length; i++){
            token_addresses[i] = rewardTokens[i];
            total_earned[i] = stakedearned[i] + IERC20(rewardTokens[i]).balanceOf(_vault);
        }

        if(_extrarewards != address(0)){
            IRewards.EarnedData[] memory extraRewards = IRewards(_extrarewards).claimableRewards(_vault);
            for(uint256 i = 0; i < extraRewards.length; i++){
                token_addresses[i+rewardTokens.length] = extraRewards[i].token;
                total_earned[i+rewardTokens.length] = extraRewards[i].amount;
            }
        }

        //add convex farm earned tokens
        for(uint256 i = 0; i < convexrewardCnt; i++){
            IConvexWrapperV2.RewardType memory rinfo = IConvexWrapperV2(_wrapper).rewards(i);
            token_addresses[i+rewardTokens.length+extraRewardsLength] = rinfo.reward_token;
            //claimed so just look at local balance
            total_earned[i+rewardTokens.length+extraRewardsLength] = IERC20(rinfo.reward_token).balanceOf(_vault);
        }
    }

}
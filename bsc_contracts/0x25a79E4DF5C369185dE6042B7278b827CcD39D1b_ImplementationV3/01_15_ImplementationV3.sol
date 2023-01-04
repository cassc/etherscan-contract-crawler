// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ImplementationV1} from "./ImplementationV1.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract ImplementationV3 is ImplementationV1{
    
    /**
     * @dev Stake NFT to the pool
     *  poolId(0), internalTxID(1)
     *  tokenId(0)
     *  admin's signature
    */
    function stakeNft(
        bytes[] memory,
        uint256[] memory, 
        bytes memory 
    ) public{
        _delegatecall(stakingHandler);
    }

    /**
    * @dev Unstake NFT
    * poolId(0), internalTxID(1)
    * NFT tokenId user want to unstake 
    */
    function unstakeNft(
        bytes[] memory,
        uint256 )
    public{
        _delegatecall(stakingHandler);
    }


    /**
     * @dev Create pool
     * poolId(0), internalTxID(1)
     * rewardFund(0)
     * startDate(0), endDate(1), duration(2), endStakedTime(3)
    */
    function createPool(bytes[] memory, uint256[] memory, uint256[] memory) public{
        _delegatecall(stakingHandler);
    }

    /**
     * @dev Update pool
     * poolId(0), internalTxID(1)
     * startDate(0), endDate(1), rewardFund(2), endStakingDate(3)
    */
    function updatePool(bytes[] memory, uint256[] memory)
        public{
        _delegatecall(stakingHandler);
    }

    /**
     * @dev Emercency withraw NFT, all staked data will be deleted, onlyProxyOwner can execute this function
     * poolId
     * user wallet address want to withdraw NFT
     * NFT tokenID user want to withdraw
    */
    function emercencyWithdrawNFT(bytes memory, address, uint256) public{
        _delegatecall(stakingHandler);
    }

    function getTotalReserve() public view returns (uint256){
        return IERC20(rewardToken).balanceOf(address(this));
    }

    /**
     * @dev Withdraw fund admin has sent to the pool
     * @param _account: the account which is used to receive fund
     * @param _amount: the amount contract owner want to withdraw
    */
    function withdrawFund(address _account, uint256 _amount) public onlySuperAdmin {
        
        // Transfer fund back to account
        IERC20(rewardToken).transfer(_account, _amount);
    }
    
    function depositFund(uint256 amount) public {
        require(isAdmin(msg.sender),"Only admin can deposit reward");
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
    }
    
    /**
     * @dev Set reward token contract address
     * @param _rewardToken: address of reward token contract
    */
    function setRewardToken(address _rewardToken) public onlySuperAdmin {
        rewardToken = _rewardToken;
    }


    /**
     * @dev Set pool active/deactive
     * @param _poolId: the pool id
     * @param _value: true/false
    */
    function setPoolActive(bytes memory _poolId, uint256 _value) public onlyAdmins {
        poolInfo[_poolId].active = _value;
    }

    /**
     * @dev Claim reward when user has staked to the pool for a period of time 
     * poolId(0), internalTxID(1)
     *  tokenId(0)
    */
    function claimReward(bytes[] memory, uint256[] memory) public {
        _delegatecall(stakingHandler);   
    }

//     /**
//      * @dev Update pool (onlyOwner)
//      * @param ids: poolId(0)
//      * @param data: rewardFund(0)
//      * @param newConfigs: startDate(0), endDate(1), duration(2), endStakedTime(3), maximumEdition (4)
//      * @param ownerConfigs: stakedAmount(0), stakedBalance(1), totalRewardClaimed(2), lastUpdateTime(3), rewardPerTokenStored(4), totalUserStaked(5)
//    */
//     function updatePoolForOwner(bytes[] memory ids, uint256[] memory data, uint256[] memory newConfigs, uint256[] memory ownerConfigs) public onlyOwner{
//         _delegatecall(stakingHandler);   
//     }

//     /**
//     * @dev Set token staking data
//     * @param poolId poolId
//     * @param addrs address list
//     * @param tokenIds tokenId list
//     */
//     function setRewardPerToken(
//         bytes memory poolId,
//         address[] memory addrs,
//         uint256[] memory tokenIds
//     ) public onlyOwner{
//         _delegatecall(stakingHandler);   
//     }
    /**
     * @dev Return amount of reward token distibuted per second
     * @param poolId: Pool id
    */
    function rewardPerToken(bytes memory poolId) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        
        // poolDuration = poolEndDate - poolStartDate
        uint256 poolDuration = pool.configs[1] - pool.configs[0]; 
        
        // Get current timestamp, if currentTimestamp > poolEndDate then poolEndDate will be currentTimestamp
        uint256 currentTimestamp = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];
        
        // If stakeBalance = 0 or poolDuration = 0
        if (pool.stakedBalance == 0 || poolDuration == 0) return 0;
        
        // If the pool has ended then stop calculate reward per token
        if (currentTimestamp < pool.lastUpdateTime) return pool.rewardPerTokenStored;
        
        // result = result * 1e18 for zero prevention
        uint256 rewardPool = pool.rewardFund * (currentTimestamp - pool.lastUpdateTime) * 1e36;
        
        // newRewardPerToken = rewardPerToken(newPeriod) + lastRewardPertoken    
        return rewardPool / (poolDuration * pool.stakedBalance) + pool.rewardPerTokenStored;
    }

    /**
     * @dev Return annual reward rate per edition
     * @param poolId: Pool id
    */
    function apy(bytes memory poolId) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        
        // poolDuration = poolEndDate - poolStartDate
        uint256 poolDuration = pool.configs[1] - pool.configs[0]; 
        
        // If stakeAmount = 0 
        if (pool.stakedAmount == 0) return pool.initialFund * ONE_YEAR_IN_SECONDS / poolDuration;
           
        return pool.initialFund * ONE_YEAR_IN_SECONDS / (poolDuration * pool.stakedAmount);
    }


    /**
     * @dev Check amount of reward a user can receive
     * @param poolId: Pool id
     * @param account: wallet address of user
     * @param tokenId: NFT token id
    */
    function earned(bytes memory poolId, address account, uint256 tokenId) 
        public
        view
        returns (uint256)
    {
        StakingData memory item = tokenStakingData[poolId][account]; 
        
            item = nftStaked[poolId][account][tokenId];
            
            // If NFT was unstaked
            if (item.unstakedTime != 0) return item.reward;
    
        
        // If staked amount = 0
        if (item.balance == 0) return 0;
        
        PoolInfo memory pool = poolInfo[poolId];
        uint256 amount = item.balance * (rewardPerToken(poolId) - item.rewardPerTokenPaid) / 1e36 + item.reward;
         
        return pool.rewardFund > amount ? amount : pool.rewardFund;
    }

    function getUnclaimedReward(uint256 [] memory tokenIds) public view returns (uint256){
        uint256 reward = 0;
        for (uint256 i = 0; i< tokenIds.length; i++){
            reward += earned(tokenStakedIn[tokenIds[i]], tokenOwnedBy[tokenIds[i]], tokenIds[i]);
        }
        return reward;
    }

    function getReward(uint256 [] memory tokenIds) public view returns (uint256[] memory){
        uint256[] memory reward = new uint256[](tokenIds.length);
        for (uint256 i = 0; i< tokenIds.length; i++){
            reward[i] += earned(tokenStakedIn[tokenIds[i]], tokenOwnedBy[tokenIds[i]], tokenIds[i]);
        }
        return reward;
    }
}
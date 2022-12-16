// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Staking.sol";
import "../../../interfaces/ISimpleRewardPool.sol";
/// @title  FixedAPRStaking 
/// @notice the APR is fixed set by admin
contract FixedAPRStaking is Staking{
    event ChangeFixedAPREvent(address account,uint256 from,uint256 to);
    uint256 public stakingType=0;
    uint256 public fixedAPRPercentage=0;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    EnumerableSet.AddressSet private stakeUsers;
    mapping(address => StakeUser) public stakeUsersInfo;
    ISimpleRewardPool public rewardPool;
    struct StakeUser {
        bool exist;
        uint256 stakeBlock;
        uint256 lastSettleBlock;
        uint256 stakeAmount;
        uint256 pendingReward;
        uint256 unbindingBlock;
        uint256 unbindingAmount;
    }
    constructor(Structs.StakingParams memory params,uint256 _fixedAPRPercentage) Staking(params) {
        fixedAPRPercentage=_fixedAPRPercentage;
    }
    modifier userStaked(address user) {
        require(stakeUsersInfo[user].exist,"!S");
        _;
    }
    /// @notice setRewardPool,a SimpleRewardPool must be set to FixedAPRStaking 
    /// @param pool, instance address of SimpleRewardPool
    function setRewardPool(address pool) public atLeastProject returns(bool){
        rewardPool=ISimpleRewardPool(pool);
        return true;
    }
    /// @notice stake
    /// @param amount, amount of stakingToken
    function stake(uint256 amount) public isWhitelisted(msg.sender) notStopped whenNotPaused nonReentrant returns(bool){
        address user=msg.sender;
        require(amount>=minStakeAmount,"!P");
        IERC20 token=IERC20(stakingToken);
        uint256 balance = token.balanceOf(user);
        require(balance>=amount,"!B");
        token.safeTransferFrom(user, address(this), amount);
        if (stakeUsersInfo[user].exist){
            require(_claimRewards(user),"CF");
            StakeUser storage stakeUser=stakeUsersInfo[user];
            stakeUser.stakeAmount=stakeUser.stakeAmount+amount;
            stakeUser.stakeBlock=block.number;
        }else{
            stakeUsersInfo[user].exist=true;
            stakeUsersInfo[user].stakeBlock=block.number;
            stakeUsersInfo[user].lastSettleBlock=block.number;
            stakeUsersInfo[user].stakeAmount=amount;
            stakeUsers.add(user);
        }
        totalStakingAmount=totalStakingAmount+amount;
        emit StakeEvent(user,stakingToken,amount);
        return true;
    }
    /// @notice stake all balance of stakingToken
    function stakeAll() public returns(bool){
        IERC20 token=IERC20(stakingToken);
        uint256 balance = token.balanceOf(msg.sender);
        return stake(balance);
    }
    /// @notice normalUnbound ,no fee be deducted,unbound amount can be withdraw after unbindPeriodBlock
    /// @param amount, amount of stakingToken
    function normalUnbound(uint256 amount) public whenNotPaused nonReentrant userStaked(msg.sender) returns(bool){
        address user=msg.sender;
        StakeUser storage stakeUser=stakeUsersInfo[user];
        require(amount > 0&&stakeUser.stakeAmount>=amount,"!B");
        require(_claimRewards(user),"CF");
        totalStakingAmount=totalStakingAmount-amount;
        stakeUser.stakeAmount=stakeUser.stakeAmount-amount;
        stakeUser.unbindingBlock=block.number;
        stakeUser.unbindingAmount=stakeUser.unbindingAmount+amount;
        emit NormalUnboundEvent(user,stakingToken,amount);
        return true;
    }
    /// @notice normalUnboundAll ,no fee be deducted
    function normalUnboundAll() public returns(bool){
        address user=msg.sender;
        normalUnbound(stakeUsersInfo[user].stakeAmount);
        return true;
    }
    /// @notice instantUnbound ,instantUnboundFeePercentage be deducted from amount,user can receive rest of amount immediately
    /// @param amount, amount of stakingToken
    function instantUnbound(uint256 amount) public whenNotPaused nonReentrant userStaked(msg.sender) returns(bool){
        require(allowedInstantUnbound,"!IS");
        address user=msg.sender;
        StakeUser storage stakeUser=stakeUsersInfo[user];
        require(amount > 0&&stakeUser.stakeAmount>=amount,"!B");
        require(_claimRewards(user),"CF");
        uint256 instantFee=amount*instantUnboundFeePercentage/uint256(10000);
        uint256 transferAmount=amount-instantFee;
        totalStakingAmount=totalStakingAmount-amount;
        stakeUser.stakeAmount=stakeUser.stakeAmount-amount;
        IERC20 token=IERC20(stakingToken);
        token.safeTransfer(user, transferAmount);
        if(instantFee>0){
            token.safeTransfer(feeAddress, instantFee);
        }
        if(stakeUser.stakeAmount==0&&stakeUser.unbindingAmount==0&&stakeUser.pendingReward==0){
            delete stakeUsersInfo[user];
            stakeUsers.remove(user);
        }
        emit InstantUnboundEvent(user,stakingToken,amount);
        return true;
    }
    /// @notice instantUnboundAll ,instantUnboundFeePercentage be deducted from amount,user can receive rest of amount immediately
    function instantUnboundAll() public returns(bool){
        address user=msg.sender;
        instantUnbound(stakeUsersInfo[user].stakeAmount);
        return true;
    }
    /// @notice withdrawUnboundAmount , users can withdraw their unbindingAmount after unbindPeriodBlock
    function withdrawUnboundAmount() public whenNotPaused nonReentrant userStaked(msg.sender) returns(bool){
        address user=msg.sender;
        StakeUser storage stakeUser=stakeUsersInfo[user];
        uint256 amount=stakeUser.unbindingAmount;
        require(amount > 0, 'A0');
        require((block.number-stakeUser.unbindingBlock)>=unboundPeriodBlock,"WF");
        require(_claimRewards(user),"CF");
        stakeUser.unbindingAmount=0;
        IERC20 token=IERC20(stakingToken);
        token.safeTransfer(user,amount);
        if(stakeUser.stakeAmount==0&&stakeUser.pendingReward==0){
            delete stakeUsersInfo[user];
            stakeUsers.remove(user);
        }
        emit WithdrawEvent(user,stakingToken,amount);
        return true;
    }
    function _claimRewards(address user) internal returns(bool){
        StakeUser storage stakeUser=stakeUsersInfo[user];
        uint256 reward=claimableRewards(user);
        if (block.number-stakeUser.lastSettleBlock<payoutIntervalBlock){
            stakeUser.pendingReward=reward;
        }else{
            require(rewardPool.claimRewards(user,reward, feeAddress,commissionPercentage),"CF");
            stakeUser.pendingReward=0;
        }
        stakeUser.lastSettleBlock=block.number;
        totalClaimedReward=totalClaimedReward+reward;
        return true;
    }
    /// @notice claimRewards , user can claim per payoutIntervalBlock
    function claimRewards() public whenNotPaused nonReentrant userStaked(msg.sender) returns(bool){
        address user=msg.sender;
        require(block.number-stakeUsersInfo[user].lastSettleBlock>=payoutIntervalBlock,"!PIB");
        return _claimRewards(user);
    }
    /// @notice claimableRewards , user can claim per payoutIntervalBlock
    /// @param user, stake user address
    /// @return Returns amount of reward
    function claimableRewards(address user) public view returns(uint256){
        StakeUser memory stakeUser=stakeUsersInfo[user];
        if (!stakeUser.exist){
            return 0;
        }
        uint256 thisReward=(block.number-stakeUser.lastSettleBlock)*stakeUser.stakeAmount*fixedAPRPercentage/(yearBlock*uint256(10000));
        return thisReward+stakeUser.pendingReward;
    }
    function _settleAllStakeUser() internal returns (bool){
        for(uint256 i=0;i<stakeUsers.length();i++){
            address userAddress=stakeUsers.at(i);
            if (!stakeUsersInfo[userAddress].exist){
                continue;
            }
            uint256 thisReward=(block.number-stakeUsersInfo[userAddress].lastSettleBlock)*stakeUsersInfo[userAddress].stakeAmount*fixedAPRPercentage/(yearBlock*uint256(10000));
            stakeUsersInfo[userAddress].lastSettleBlock=block.number;
            stakeUsersInfo[userAddress].pendingReward=stakeUsersInfo[userAddress].pendingReward+thisReward;
        }
        return true;
    }
    function getAllUnpaidReward() internal view returns(uint256 totalReward){
        for(uint256 i=0;i<stakeUsers.length();i++){
            address userAddress=stakeUsers.at(i);
            if (!stakeUsersInfo[userAddress].exist){
                continue;
            }
            uint256 thisReward=(block.number-stakeUsersInfo[userAddress].lastSettleBlock)*stakeUsersInfo[userAddress].stakeAmount*fixedAPRPercentage/(yearBlock*uint256(10000));
            totalReward=totalReward+thisReward+stakeUsersInfo[userAddress].pendingReward;
        }
        return totalReward;
    }
    /// @notice setFixedAPRPercentage , admin can change FixedAPR, Before APR be changed all user's rewards should be settled
    /// @param aprPer,apr can be infinity
    function setFixedAPRPercentage(uint256 aprPer) public nonReentrant atLeastProject{
        require(_settleAllStakeUser(),"SAS");
        uint256 origin=fixedAPRPercentage;
        fixedAPRPercentage=aprPer;
        emit ChangeFixedAPREvent(msg.sender,origin,fixedAPRPercentage);
    }
    /// @notice getRewardDebt
    /// @return totalRewardInPool 
    /// @return totalStakingAmount
    /// @return totalUnpaidReward 
    function getRewardDebt() public view returns(uint256,uint256,uint256){
        uint256 totalRewardInPool_=IERC20(stakingToken).balanceOf(address(rewardPool));
        uint256 totalUnpaidReward_=getAllUnpaidReward();
        return (totalRewardInPool_,totalStakingAmount,totalUnpaidReward_);
    }
    /// @notice getStakeUserCount
    function getStakeUserCount() public view returns (uint256){
        return stakeUsers.length();
    }

}
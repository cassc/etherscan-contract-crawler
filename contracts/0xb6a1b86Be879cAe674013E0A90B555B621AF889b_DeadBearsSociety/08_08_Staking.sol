// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Staking {

    constructor() {

        stakeholders.push();

    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint256 claimable;

    }

    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    uint256 public _rewardRateBull = 1000;
    uint256 public _rewardRateBear = 1000;

    Stakeholder[] internal stakeholders;

    mapping(address => uint256) internal stakes;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    function _addStakeHolder(address staker) internal returns (uint256){
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;

        stakeholders[userIndex].user = staker;

        stakes[staker] = userIndex;

        return userIndex;
    }

    function _stake(uint256 _amount) internal {
        require(_amount > 0);

        uint256 index = stakes[msg.sender];

        uint256 timestamp = block.timestamp;

        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeHolder(msg.sender);

            stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, 0));

            emit Staked(msg.sender, _amount, index,timestamp);
        }
    }

    function calculateStakeRewardBull(Stake memory _current_stake) internal view returns(uint256){
        return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / _rewardRateBull;
    }

    function calculateStakeRewardBear(Stake memory _current_stake) internal view returns(uint256){
        return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / _rewardRateBear;
    }


    function _withdrawStakeBull(uint256 amount, uint256 index) internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeRewardBull(current_stake);
         // Remove by subtracting the money unstaked 
         current_stake.amount = current_stake.amount - amount;
         // If stake is empty, 0, then remove it from the array of stakes
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
             // If not empty then replace the value of it
             stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
             // Reset timer of stake
            stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;

     }

        function _withdrawStakeBear(uint256 amount, uint256 index) internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeRewardBear(current_stake);
         // Remove by subtracting the money unstaked 
         current_stake.amount = current_stake.amount - amount;
         // If stake is empty, 0, then remove it from the array of stakes
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
             // If not empty then replace the value of it
             stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
             // Reset timer of stake
            stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;

     }

         function hasStakeBull(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeRewardBull(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
        return summary;
    }

        function hasStakeBear(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeRewardBear(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
        return summary;
    }

}
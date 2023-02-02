// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
───────▄▀▀▀▀▀▀▀▀▀▀▄▄
────▄▀▀░░░░░░░░░░░░░▀▄
──▄▀░░░░░░░░░░░░░░░░░░▀▄
──█░░░░░░░░░░░░░░░░░░░░░▀▄
─▐▌░░░░░░░░▄▄▄▄▄▄▄░░░░░░░▐▌
─█░░░░░░░░░░░▄▄▄▄░░▀▀▀▀▀░░█
▐▌░░░░░░░▀▀▀▀░░░░░▀▀▀▀▀░░░▐▌
█░░░░░░░░░▄▄▀▀▀▀▀░░░░▀▀▀▀▄░█
█░░░░░░░░░░░░░░░░▀░░░▐░░░░░▐▌
▐▌░░░░░░░░░▐▀▀██▄░░░░░░▄▄▄░▐▌
─█░░░░░░░░░░░▀▀▀░░░░░░▀▀██░░█
─▐▌░░░░▄░░░░░░░░░░░░░▌░░░░░░█
──▐▌░░▐░░░░░░░░░░░░░░▀▄░░░░░█
───█░░░▌░░░░░░░░▐▀░░░░▄▀░░░▐▌
───▐▌░░▀▄░░░░░░░░▀░▀░▀▀░░░▄▀
───▐▌░░▐▀▄░░░░░░░░░░░░░░░░█
───▐▌░░░▌░▀▄░░░░▀▀▀▀▀▀░░░█
───█░░░▀░░░░▀▄░░░░░░░░░░▄▀
──▐▌░░░░░░░░░░▀▄░░░░░░▄▀
─▄▀░░░▄▀░░░░░░░░▀▀▀▀█▀
▀░░░▄▀░░░░░░░░░░▀░░░▀▀▀▀▄▄▄▄▄
/$$      /$$                         /$$              /$$$$$$   /$$               /$$       /$$                    
| $$  /$ | $$                        | $$             /$$__  $$ | $$              | $$      |__/                    
| $$ /$$$| $$  /$$$$$$  /$$  /$$$$$$ | $$   /$$      | $$  \__//$$$$$$    /$$$$$$ | $$   /$$ /$$ /$$$$$$$   /$$$$$$ 
| $$/$$ $$ $$ /$$__  $$|__/ |____  $$| $$  /$$/      |  $$$$$$|_  $$_/   |____  $$| $$  /$$/| $$| $$__  $$ /$$__  $$
| $$$$_  $$$$| $$  \ $$ /$$  /$$$$$$$| $$$$$$/        \____  $$ | $$      /$$$$$$$| $$$$$$/ | $$| $$  \ $$| $$  \ $$
| $$$/ \  $$$| $$  | $$| $$ /$$__  $$| $$_  $$        /$$  \ $$ | $$ /$$ /$$__  $$| $$_  $$ | $$| $$  | $$| $$  | $$
| $$/   \  $$|  $$$$$$/| $$|  $$$$$$$| $$ \  $$      |  $$$$$$/ |  $$$$/|  $$$$$$$| $$ \  $$| $$| $$  | $$|  $$$$$$$
|__/     \__/ \______/ | $$ \_______/|__/  \__/       \______/   \___/   \_______/|__/  \__/|__/|__/  |__/ \____  $$
                  /$$  | $$                                                                                /$$  \ $$
                 |  $$$$$$/                                                                               |  $$$$$$/
                  \______/                                                                                 \______/ 
*/

/**
* @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
*/
contract Stakeable {

// 3600 is hourly    
    uint rewardsEvery = 3600;
// 35000 is .00286% per hour. Roughly 25% (.00286* 24 *365) annually
    uint256 internal rewardPerHour = 35000;

    /**
    * @notice Constructor since this contract is not ment to be used without inheritance
    * push once to stakeholders for it to work proplerly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }
    /**
     * @notice
     * A stake struct is used to represent the way we store stakes, 
     * A Stake will contain the users address, the amount staked and a timestamp, 
     * Since which is when the stake was made
     */
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        uint256 claimable;
    }
    /**
    * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
        
    }
     /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */ 
     struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
     }

    /**
    * @notice 
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stakeholder[] internal stakeholders;
    /**
    * @notice 
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
     event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);



    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex; 
    }


    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    function _stake(uint256 _amount) internal{
        // Simple check so that user does not stake 0 
        require(_amount > 0, "Cannot stake nothing");
        

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));
        // Emit an event that the stake has occured
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
     // can alter amount using sqrt 
      function calculateStakeReward(Stake memory _current_stake) internal view virtual returns(uint256){
          // First calculate how long the stake has been active
          // Use current seconds since epoch - the seconds since epoch the stake was made
          // The output will be duration in SECONDS ,
          // We will reward the user 0.1% per Hour So thats 0.1% per 3600 seconds
          // the alghoritm is  seconds = block.timestamp - stake seconds (block.timestap - _stake.since)
          // hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
          // we then multiply each token by the hours staked , then divide by the rewardPerHour rate
          return (((block.timestamp - _current_stake.since) / rewardsEvery ) * _current_stake.amount) / rewardPerHour;
         }


          function getMyStakeRewardEstimate(uint256 index) public view virtual returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        uint256 cStake = stakeholders[user_index].address_stakes[index].amount;
        uint256 cSince = stakeholders[user_index].address_stakes[index].since;
          return (((block.timestamp - cSince) / rewardsEvery ) * cStake) / rewardPerHour;

     }



    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
    */
     function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeReward(current_stake);
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

     /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function listUserStakes(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
        return summary;
    }



    function getMyTotalStake () public view returns (uint myTotalStake) {
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[stakes[msg.sender]].user]].address_stakes);
            for (uint256 s = 0; s < summary.stakes.length; s += 1){
                myTotalStake = myTotalStake + summary.stakes[s].amount ;
    }
        return myTotalStake;
    }



    /**
    * @notice Loops through stakeholders array to retrie TotalStaked
     */
    function getGlobalTotalStaked () public view returns (uint globalStakeAmount) {
//        uint256 globalStakeAmount;

//        StakingGlobal memory globalSummary = StakingGlobal(0, stakeholders[stakes[_staker]].address_stakes);        
        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = 0; i < stakeholders.length ; i += 1){
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[i].user]].address_stakes);
            for (uint256 s = 0; s < summary.stakes.length; s += 1){
//           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
//           summary.stakes[s].claimable = availableReward;
           globalStakeAmount = globalStakeAmount+summary.stakes[s].amount;
       }}
      return globalStakeAmount;
    }

      function getGlobalStakeRewardEstimate() public view virtual returns(uint256){
        uint256 cStake;
        uint256 cSince;
        uint256 getRewardAmount;
        uint256 allRewards;
        for (uint256 i = 0; i < stakeholders.length ; i += 1){
          StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[stakeholders[i].user]].address_stakes);
          for (uint256 s = 0; s < summary.stakes.length; s += 1){
//           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
//           summary.stakes[s].claimable = availableReward;
            cStake = stakeholders[i].address_stakes[s].amount;
            cSince = stakeholders[i].address_stakes[s].since;
            getRewardAmount = (((block.timestamp - cSince) / rewardsEvery ) * cStake) / rewardPerHour;
            allRewards += getRewardAmount ;
        }}
        return allRewards;
    }


}
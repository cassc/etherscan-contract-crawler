// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

error NoRewardToWithdraw();
import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title Wealthy Teds Staking Contract
/// @author 0xSimon_
/// @notice This contract allows Wealthy Teds holders to stake their ERC721 in return for ETH Rewards. Rewards are earned on a per-round basis and users must register for the newest round.
/// @dev to do: Explain to a developer any extra details


contract WealthyTedsStake is Ownable {
    address public wealthyTeds = 0xaB28a4780Ce7202b0959eaBdF9cb4FD7f9249cB9;
    address public rewardAggregator;
    uint public numNfts = 1200;
    uint blockTimestamp;
    uint public currentRound = 0;

    mapping(address => mapping(uint => StakerRoundStats)) public stakerRoundStats;
    mapping(address => GeneralStakerInfo) public generalStakerInfo;
    mapping(uint => address) public owners;
    mapping(uint => StakingRound) public stakingRounds;
    bool private roundZeroSet;


    struct GeneralStakerInfo  {
        uint[] tokenIds;
        uint lastRound;
        uint numNftsStaked;
        uint totalRewardsEarnedLeaderboard;

    }
    struct StakerRoundStats {
        uint accumulatedRewards;
        uint lastUpdateTimestamp;
    }
    struct StakingRound {
        uint startTimestamp;
        uint endTimestamp;
        uint rewardPerSecond;
        uint duration;
    }


    constructor(){
        blockTimestamp = block.timestamp;
    }

    event STARTED_STAKE(uint indexed stakingRound, address indexed staker, uint timestamp,uint numberOfNftsStaked);
    event STOPPED_STAKE(uint indexed stakingRound, address indexed staker, uint timestamp,uint numberOfNftsUnstaked);
    event REWARD_CLAIMED(uint indexed stakingRound, address indexed staker, uint timestamp, uint reward);
    event REGISTERED_FOR_ROUND(uint indexed stakingRound, address indexed staker, uint timestamp);

    function setWealthyTeds(address _address) public onlyOwner {
        wealthyTeds = _address;
    }

    modifier updateReward(address account) {
        uint reward = nextRewardForRound(currentRound, account);
        uint userLastRound =   generalStakerInfo[account].lastRound;
        stakerRoundStats[msg.sender][currentRound].accumulatedRewards += reward;
        generalStakerInfo[msg.sender].totalRewardsEarnedLeaderboard += reward;




        if(userLastRound != currentRound) {
            uint rewardForLastRound = nextRewardForRound(userLastRound, account);
            stakerRoundStats[account][userLastRound].accumulatedRewards += rewardForLastRound;
            stakerRoundStats[account][userLastRound].lastUpdateTimestamp = block.timestamp > stakingRounds[userLastRound].endTimestamp ? stakingRounds[userLastRound].endTimestamp : block.timestamp;
            generalStakerInfo[msg.sender].totalRewardsEarnedLeaderboard += reward;

        }

        stakerRoundStats[account][currentRound].lastUpdateTimestamp = block.timestamp > stakingRounds[currentRound].endTimestamp ? stakingRounds[currentRound].endTimestamp : block.timestamp;
        generalStakerInfo[account].lastRound = currentRound;
        _;
    }

    function nextRewardForRound(uint roundNumber,address account) public view returns(uint256) {
        if(stakerRoundStats[account][roundNumber].lastUpdateTimestamp == 0 ) {
            return 0;
        }
        uint nextReward = 0;
        uint maxTimestamp = block.timestamp > stakingRounds[roundNumber].endTimestamp ? stakingRounds[roundNumber].endTimestamp : block.timestamp;

        //Can never be greater than the end timestamp. That logic is handled in the updateReward modifier.
        uint userTimestamp = stakerRoundStats[account][roundNumber].lastUpdateTimestamp;
        uint timeSinceLastUpdate = maxTimestamp - userTimestamp;

        if (generalStakerInfo[account].numNftsStaked > 0) {
            nextReward = generalStakerInfo[account].numNftsStaked * stakingRounds[roundNumber].rewardPerSecond * timeSinceLastUpdate;
        }
        return nextReward;
    }

    function setNewStakingRound(uint durationInDays, uint _numNfts) external payable onlyOwner{
        require(roundZeroSet,"Must Have Initialized Round 0");
        //Prevents Underflow
        require(block.timestamp > stakingRounds[currentRound].endTimestamp,"Last Round Must End Before Starting New Round");
        numNfts = _numNfts;
        currentRound++;
        uint maxDuration = durationInDays * uint(1 days);
        stakingRounds[currentRound].endTimestamp = block.timestamp + maxDuration;
        stakingRounds[currentRound].duration = maxDuration;
        stakingRounds[currentRound].rewardPerSecond = (msg.value / numNfts) / (durationInDays  * uint (1 days));
        stakingRounds[currentRound].startTimestamp = block.timestamp;

    }



    function setRoundZero(uint durationInDays, uint _numNfts) external payable onlyOwner{
        require(!roundZeroSet,"Can Only Be Used On Round Zero");
        //@dev in days
        numNfts = _numNfts;
        uint maxDuration = durationInDays * uint(1 days);
        stakingRounds[currentRound].endTimestamp = block.timestamp + maxDuration;
        stakingRounds[currentRound].duration = maxDuration;
        stakingRounds[currentRound].rewardPerSecond = (msg.value / numNfts) / (durationInDays  * uint (1 days));
        stakingRounds[currentRound].startTimestamp = block.timestamp;

        roundZeroSet =true;

    }

    function setNumNfts(uint _numNfts) external onlyOwner{
        numNfts = _numNfts;
    }

    function viewContractBalance() external view returns(uint){
        return address(this).balance;
    }

    function viewReward(uint roundNumber) public view returns(uint) {
        return stakerRoundStats[msg.sender][roundNumber].accumulatedRewards + nextRewardForRound(roundNumber,msg.sender);
    }
    function viewWalletReward(uint roundNumber,address account) public view returns(uint) {
        return stakerRoundStats[msg.sender][roundNumber].accumulatedRewards + nextRewardForRound(roundNumber,account);
    }


    function withdrawRewardForRound(uint roundNumber) public updateReward(msg.sender){
        uint reward = viewReward(roundNumber);
        if(reward == 0 ) revert  NoRewardToWithdraw();
        stakerRoundStats[msg.sender][roundNumber].accumulatedRewards = 0;
        stakerRoundStats[msg.sender][roundNumber].lastUpdateTimestamp = block.timestamp > stakingRounds[roundNumber].endTimestamp ? stakingRounds[roundNumber].endTimestamp : block.timestamp;
        (bool os, ) = payable(msg.sender).call{value: reward}("");
        require(os);
    }
    function withdrawRewardsForRounds(uint[] calldata rounds) external {
        for(uint i = 0; i < rounds.length; i++) {
            withdrawRewardForRound(rounds[i]);
        }
    }




    function withdrawReward(uint roundNumber,address account) external {
        require(msg.sender == rewardAggregator,"Unauthorized");
        uint256 reward = viewReward(roundNumber);
        if(reward == 0 ) revert  NoRewardToWithdraw();
        stakerRoundStats[msg.sender][roundNumber].accumulatedRewards = 0;
        stakerRoundStats[msg.sender][roundNumber].lastUpdateTimestamp = block.timestamp > stakingRounds[roundNumber].endTimestamp ? stakingRounds[roundNumber].endTimestamp : block.timestamp;
        (bool os, ) = payable(account).call{value: reward}("");
        require(os);
        emit REWARD_CLAIMED(currentRound, msg.sender, block.timestamp,reward);
    }


 /*/////////////////////////////////////////////////
           HELPER FUNCTIONS:::::
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/

    function removeElement(uint element, uint[] storage tokenIds) internal {
        for(uint i; i<tokenIds.length;i++){
            if(element == tokenIds[i]){
                tokenIds[i] = tokenIds[tokenIds.length -1];
                tokenIds.pop();
                return;
            }
        }
    }


    function batchStake(uint256[] calldata tokenIds) external updateReward(msg.sender) {
        require(roundZeroSet,"Staking Not Active");
        for(uint256 i; i<tokenIds.length; i++){
            ERC721(wealthyTeds).transferFrom(msg.sender,address(this),tokenIds[i]);
            owners[tokenIds[i]] = msg.sender;
            generalStakerInfo[msg.sender].tokenIds.push(tokenIds[i]);
        }
        generalStakerInfo[msg.sender].numNftsStaked+= tokenIds.length;
        emit STARTED_STAKE(currentRound, msg.sender, block.timestamp,tokenIds.length);
    }

    function batchUnstake (uint256[] calldata tokenIds) external updateReward(msg.sender) {
        require(roundZeroSet,"Staking Not Active");
        for(uint256 i; i<tokenIds.length;i++) {
            require(owners[tokenIds[i]] != address(0),"Cannot Be Zero Address");
            require(msg.sender == owners[tokenIds[i]],"Invalid Owner");
            ERC721(wealthyTeds).transferFrom(address(this),msg.sender,tokenIds[i]);
            removeElement(tokenIds[i],generalStakerInfo[msg.sender].tokenIds);
            delete owners[tokenIds[i]];
        }
        generalStakerInfo[msg.sender].numNftsStaked-= tokenIds.length;
        emit STOPPED_STAKE(currentRound, msg.sender, block.timestamp,tokenIds.length);
    }

    function registerForNewRound() external updateReward(msg.sender) {
        emit REGISTERED_FOR_ROUND(currentRound, msg.sender, block.timestamp);

    }

    function getTedsStaked(address user) public view returns(uint256[] memory){
        return generalStakerInfo[user].tokenIds;
    }
    function getTedsStakedByIndex(address user, uint index) public view returns(uint){
        return generalStakerInfo[user].tokenIds[index];
    }
    function getTedsLength(address account) public view returns(uint){
        return generalStakerInfo[account].tokenIds.length;
    }
    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        (bool os,) = payable(owner()).call{value:contractBalance}("");
        require(os);
    }

}





interface ERC721 {
    function transferFrom(address from, address to,uint256 tokenId) external;
}

////////////////////------------------------------------------------------------
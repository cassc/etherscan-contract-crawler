//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./MBCStakingCalculation.sol";

contract MBCStakingUniversal is MBCStakingCalculation {

    // Get Level Downline With Bonus And Bonus Percentage
    function level_downline(address _user,uint _level) view public returns(uint _noOfUser, uint256 _investment,uint256 _bonusper, uint256 _bonus){
       return (useraffiliatedetails[_user].refs[_level],useraffiliatedetails[_user].levelWiseBusiness[_level],ref_bonuses[_level],useraffiliatedetails[_user].levelWiseBonus[_level]);
    }

    // Get Level Downline With Bonus And Bonus Percentage
    function staking_reward_tier(address _user,uint _tier) view public returns(uint256 _userId,uint256 _totalReward,uint256 _rewards,uint256 _totalRewardWithdrawal,uint256 _totalRewardStaked,uint256 _penaltyCollected){
       UserStakingDetails storage usertier = userstakingdetails[_user];
       return (usertier.userId,usertier.totalReward[_tier],usertier.rewards[_tier],usertier.totalRewardWithdrawal[_tier],usertier.totalRewardStaked[_tier],usertier.penaltyCollected[_tier]);
    }

    // Get Level Downline With Bonus And Bonus Percentage
    function staking_tier(address _user,uint _tier) view public returns(uint256 _userId,uint256 _totalStakedAvailable,uint256 _totalUnLockedStaked,uint256 _totalLockedStaked,uint256 _totalStaked,uint256 _totalUnStaked){
       UserStakingDetails storage usertier = userstakingdetails[_user];
       return (usertier.userId,usertier.totalStakedAvailable[_tier],usertier.totalUnLockedStaked[_tier],usertier.totalLockedStaked[_tier],usertier.totalStaked[_tier],usertier.totalUnStaked[_tier]);
    }

     //Get User Total Staked Amount
    function GETTotalStakedGE(address account) public view returns(uint256){
        UserOverallDetails storage useroverall = useraggregatedetails[account];
        return (useroverall.totalStakedAvailable);
    }

    // View Get Current Time Stamp
    function view_GetCurrentTimeStamp() public view returns(uint _timestamp){
       return (block.timestamp);
    }

    // View No Second Between Two Date & Time
    function view_DiffTwoDate(uint _startDate,uint _endDate) public pure returns(uint _second,uint _hour,uint _days,uint _year){
        uint startDate = _startDate;
        uint endDate = _endDate;
        uint datediffs = (endDate - startDate);
        uint datediffh = (endDate - startDate) / 60 / 60;
        uint datediffd = (endDate - startDate)/ 60 / 60 / 24;
        uint yeardiff = (datediffd) / 365 ;
        return (datediffs,datediffh,datediffd,yeardiff);
    }
    
    // Update Year Tier Slab
    // _tier=0 Then Year 1st
    // _tier=1 Then Year 2nd
    // _tier=2 Then Year 3rd
    function update_TierYear(uint _tier,uint256 _tierYearSlab,uint256 _tierAPY,uint256 _tierLocking,uint256 _stakePenaltySlab) public {
      require(contractOwner==msg.sender, 'Admin what?');
      tierYearSlab[_tier]=_tierYearSlab;
      tierAPY[_tier]=_tierAPY;
      tierLocking[_tier]=_tierLocking;
      stakePenaltySlab[_tier]=_stakePenaltySlab;
    }

    // Update Affiliate Settings
    function affiliate_Settings(uint256 _lockingDays,uint256 _minimumWithdrawal,uint256 _adminCharge) public {
      require(contractOwner==msg.sender, 'Admin what?');
      lockingDays=_lockingDays;
      minimumWithdrawal=_minimumWithdrawal;
      adminCharge=_adminCharge; 
    }

    // Update Level Income Percentage
    function update_LevelIncomeSlab(uint256 _index,uint256 _percentage) public {
      require(contractOwner==msg.sender, 'Admin what?');
      ref_bonuses[_index]=_percentage;
    }

    // Update Direct Required For Qualify Level
    function update_DirectRequiredForLevelQualify(uint256 _index,uint256 _noofdirect) public {
      require(contractOwner==msg.sender, 'Admin what?');
      requiredDirect[_index]=_noofdirect;
    }

    // Update Staking Reward Status
    function update_StakingRewardStaus(address _user,bool _stakingStatus,bool _affiliateIncomeStatus) public {
      require(contractOwner==msg.sender, 'Admin what?');
      UserStakingDetails storage usertier = userstakingdetails[_user];
      usertier.stakingStatus[0] = _stakingStatus;
      usertier.stakingStatus[1] = _stakingStatus;
      usertier.stakingStatus[2] = _stakingStatus;
      UserAffiliateDetails storage useraffiliate = useraffiliatedetails[msg.sender];   
      useraffiliate.isIncomeBlocked = _affiliateIncomeStatus;
    }

    function update_AwardRewardSettings(uint256 _tier,uint256 _requiredBusiness,uint256 _requiredLevel,uint256 _requiredNoofId,uint256 _reward) public {
      require(contractOwner==msg.sender, 'Admin what?');
      requiredBusiness[_tier]=_requiredBusiness;
      requiredLevel[_tier]=_requiredLevel;
      requiredNoofId[_tier]=_requiredNoofId;
      reward[_tier]=_reward;
    }

    // Update Staking
    function verify_StakingTransaction(uint256 _totalNumberofStakers,uint256 _totalTierOneStakers,uint256 _totalTierTwoStakers,uint256 _totalTierThreeStakers) public {
      require(contractOwner==msg.sender, 'Admin what?');
      totalNumberofStakers += _totalNumberofStakers;
      totalTierOneStakers += _totalTierOneStakers;
      totalTierTwoStakers += _totalTierTwoStakers;
      totalTierThreeStakers += _totalTierThreeStakers;
    }

    function rewardPerDayToken(address account,uint _tierslab) public view returns (uint256 perdayinterest) {
        uint256 _perdayinterest=0;
        if (userstakingdetails[account].totalStakedAvailable[_tierslab] <= 0 || userstakingdetails[account].stakingStatus[_tierslab] == false) {
            return _perdayinterest;
        }
        else{
            uint256 StakingToken=userstakingdetails[account].totalStakedAvailable[_tierslab];
            uint256 APYPer=tierAPY[_tierslab];
            uint256 perDayPer=((APYPer*1e18)/(365*1e18));
            _perdayinterest=((StakingToken*perDayPer)/100)/1e18;
            return _perdayinterest;
        }
    }

    function earned(address account,uint _tierslab) public view returns (uint256 totalearnedinterest) {
        (uint noofSecond, uint noofHour, uint noofDay,uint noofYear) = view_DiffTwoDate(userstakingdetails[account].lastUpdateTime[_tierslab],block.timestamp);
        uint256 _perdayinterest=rewardPerDayToken(account,_tierslab);
        return((_perdayinterest * noofDay)+userstakingdetails[account].rewards[_tierslab]);
    }

    modifier updateReward(address account,uint256 _tierslab) {
        UserStakingDetails storage user = userstakingdetails[account];
        userstakingdetails[account].rewards[_tierslab] = earned(account,_tierslab);
        user.lastUpdateTime[_tierslab] = block.timestamp;
        _;
    }

    function _totalBonus(address _user) public view returns(uint256 _availableBonus) {
      UserAffiliateDetails storage useraffiliate = useraffiliatedetails[_user];
      uint256 dailyReleasePer = 100*1e18 / lockingDays*1e18;
      uint256 levelIncomeReleasable = ((useraffiliatedetails[_user].creditedLevelBonus) * dailyReleasePer)/(100*1e18);
      levelIncomeReleasable /= 1e18;
      if(levelIncomeReleasable>useraffiliatedetails[_user].availableLevelBonus)
      {
        levelIncomeReleasable=0;
      }
      (uint noofTotalSecond, uint noofHour, uint noofDay,uint noofYear) = view_DiffTwoDate(useraffiliate.checkpoint,block.timestamp);
      levelIncomeReleasable *= noofDay;
      uint256 TotalBonus = 0;
 //     TotalBonus += useraffiliate.availableJackpotBonus;
      TotalBonus += useraffiliate.availableAwardRewardBonus; 
      TotalBonus += levelIncomeReleasable;
      return (TotalBonus);
    }

    // Verify Staking By Admin In Case If Needed
    function _VerifyStake(uint _amount) public {
        require(contractOwner==msg.sender, 'Admin what?');
        nativetoken.transferFrom(msg.sender, address(this), _amount);
    }

     // Verify Un Staking By Admin In Case If Needed
    function _VerifyUnStake(uint _amount) public {
        require(contractOwner==msg.sender, 'Admin what?');
        require(_amount >= nativetoken.balanceOf(address(this)),'Insufficient MBC For Collect');
        nativetoken.transfer(contractOwner, _amount);
    }

    //Get Un Staking Penalty Percentage According To Time
    function getUnStakePenaltyPer(uint _startDate,uint _endDate,uint256 _tierslab) public view returns(uint penalty){
        (uint noofSecond, uint noofHour, uint noofDay,uint noofYear) = view_DiffTwoDate(_startDate,_endDate);
        uint _penalty=0;
        if(noofYear < tierYearSlab[_tierslab]) {
           _penalty=stakePenaltySlab[_tierslab];
        }
        return (_penalty);
    }

   function getUserPenaltyDetails(address account,uint256 _tierslab) public view returns (uint256 _penaltyPer,uint _noofHour,uint _stakedYear,uint _stakedDay,uint _nooftotalSecond) {
        UserStakingDetails storage usertier = userstakingdetails[account];
        uint lastStakedUpdateTime=usertier.lastStakedUpdateTime[_tierslab];
        (uint noofTotalSecond, uint noofHour, uint stakedDay,uint stakedYear) = view_DiffTwoDate(lastStakedUpdateTime,block.timestamp);
        uint penaltyPer=getUnStakePenaltyPer(lastStakedUpdateTime,block.timestamp,_tierslab);
        return(penaltyPer,noofHour,stakedYear,stakedDay,noofTotalSecond);
   }
}

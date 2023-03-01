//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value); 
}

contract MBCStakingInitialize {

    IBEP20 public nativetoken;

    address public contractOwner;

    uint256 public lockingDays=200;
    uint256 public adminCharge=10;
    uint256 public minimumWithdrawal=1000000000000000000;

    uint256 public totalNumberofStakers;
    uint256 public totalTierOneStakers;
    uint256 public totalTierTwoStakers;
    uint256 public totalTierThreeStakers;

	uint256 public totalStakesGE;
    uint256 public totalLevelIncome;
    uint256 public totalAwardAndReward;

    //Index For Every Thing Will Start From 0,1,2
    uint256[3] public tierYearSlab = [1,2,3];
    uint256[3] public tierAPY = [60 ether,120 ether,140 ether];
    uint256[3] public tierLocking = [70,70,70];
    uint256[3] public stakePenaltySlab = [3,3,3];

    struct UserStakingDetails {
        uint256 userId;
        bool[3] stakingStatus;
        uint256[3] totalStakedAvailable;
        uint256[3] totalUnLockedStaked;
        uint256[3] totalLockedStaked;
        uint256[3] totalStaked;
        uint256[3] totalUnStaked;
        uint256[3] totalReward;
        uint256[3] rewards;
		uint256[3] totalRewardWithdrawal;
		uint256[3] totalRewardStaked;
        uint256[3] penaltyCollected;
        uint[3] lastStakedUpdateTime;
        uint[3] lastUnStakedUpdateTime;
        uint[3] lastUpdateTime;
	}

    struct UserOverallDetails {
        uint256 totalStakedAvailable;
        uint256 totalUnLockedStaked;
        uint256 totalLockedStaked;
        uint256 totalStaked;
        uint256 totalUnStaked;
        uint256 totalReward;
		uint256 totalRewardWithdrawal;
		uint256 totalRewardStaked;
        uint256 penaltyCollected;
        uint lastStakedUpdateTime;
        uint lastUnStakedUpdateTime;
        uint lastUpdateTime;
    }

    struct UserAffiliateDetails {
        uint256 checkpoint;
        bool isIncomeBlocked;
        address referrer;
		uint256 totalReferrer;
        uint256 totalBusiness;
        uint256 availableAwardRewardBonus;
		uint256 awardRewardBonusWithdrawn;
        uint256 creditedLevelBonus;
		uint256 availableLevelBonus;
		uint256 levelBonusWithdrawn;        		
		uint256[20] levelWiseBusiness;
        uint256[20] levelWiseBonus;
		uint[20] refs;
        string[20] allIds;        
    }

    struct UserRewardDetails {
        bool tierfirstreceived;
        bool tiersecondreceived;
        bool tierthirdreceived;
        bool tierfourthreceived;
        bool tierfifthreceived;
    }

    // Index For Every Thing Will Start From 0,1,2

    uint[20] public ref_bonuses = [20,10,5,5,5,3,3,3,3,3,2,2,2,2,2,1,1,1,1,1]; 
    uint[20] public requiredDirect = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];

    uint[5]  public requiredBusiness = [5000000000000000000000000,10000000000000000000000000,30000000000000000000000000,100000000000000000000000000,200000000000000000000000000];
    uint[5]  public requiredLevel = [3,6,10,14,20];
    uint[5]  public requiredNoofId = [25,100,300,1000,3000];
    uint[5]  public reward= [50000000000000000000000,100000000000000000000000,300000000000000000000000,1000000000000000000000000,2000000000000000000000000];

    mapping (address => UserStakingDetails) public userstakingdetails;
    mapping (address => UserOverallDetails) public useraggregatedetails;
    mapping (address => UserAffiliateDetails) public useraffiliatedetails;
    mapping (address => UserRewardDetails) public userrewarddetails;

	event Staking(address indexed _user, uint256 _amount,uint256 _tierslab);
	event UnStakeUnlockedAmount(address indexed _user, uint256 _amount,uint256 _tierslab);
	event UnStakeLockedAmount(address indexed _user, uint256 _amount,uint256 _tierslab);
    event RewardWithdrawal(address indexed _user, uint256 _amount,uint256 _tierslab);
    event RewardStaking(address indexed _user, uint256 _amount,uint256 _tierslab);
	event Withdrawn(address indexed _user, uint256 _amount);

    constructor() {
        contractOwner = 0x6D24d7856dceF3F389Ad3483564FEA59B5bE1F1A;
        nativetoken = IBEP20(0x1ae848CA067AdEA97b05a729b4cEcdAdefa84d07);
        useraffiliatedetails[contractOwner].checkpoint = block.timestamp;
        userstakingdetails[contractOwner].userId = block.timestamp;
    }
}
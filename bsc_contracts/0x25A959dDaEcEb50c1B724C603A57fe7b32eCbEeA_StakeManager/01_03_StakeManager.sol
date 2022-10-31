// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract StakeManager is Ownable{

    struct UserInfo {

        uint256 totalStakedDefault; //linear
        uint256 totalStakedAutoCompound;

        uint256 walletStartTime;
        uint256 overThresholdTimeCounter;

        uint256 activeStakesCount;
        uint256 withdrawStakesCount;

        mapping(uint256 => StakeInfo) activeStakes;
        mapping(uint256 => WithdrawnStakeInfo) withdrawnStakes;

    }

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        bool isAutoPool;
    } 

    struct StakeInfoView {
        uint256 stakeID;
        uint256 taxReduction;
        uint256 amount;
        uint256 startTime;
        bool isAutoPool;
    } 

    struct WithdrawnStakeInfo {
        uint256 amount;
        uint256 taxReduction;
        uint256 endTime;
        bool isAutoPool;
    }

    struct WithdrawnStakeInfoView {
        uint256 stakeID;
        uint256 amount;
        uint256 taxReduction;
        uint256 endTime;
        bool isAutoPool;

    }


    address public DogPoundManger;
    mapping(address => UserInfo) userInfo;


    uint256 public reliefPerDay = 75;      // 0.75% default
    uint256 public reliefPerDayExtra = 25; // 0.25%

    constructor(address _DogPoundManger){
        DogPoundManger = _DogPoundManger;
    }

    modifier onlyDogPoundManager() {
        require(DogPoundManger == msg.sender, "manager only");
        _;
    }

    function saveStake(address _user, uint256 _amount, bool _isAutoCompound) onlyDogPoundManager external{
        UserInfo storage user = userInfo[_user];
        user.activeStakes[user.activeStakesCount].amount = _amount;
        user.activeStakes[user.activeStakesCount].startTime = block.timestamp;
        user.activeStakes[user.activeStakesCount].isAutoPool = _isAutoCompound;
        user.activeStakesCount++;
        if(_isAutoCompound){
            user.totalStakedAutoCompound += _amount;
        }else{
            user.totalStakedDefault += _amount;
        }
    }

    function withdrawFromStake(address _user,uint256 _amount, uint256 _stakeID) onlyDogPoundManager  external{
        UserInfo storage user = userInfo[_user];
        StakeInfo storage activeStake = user.activeStakes[_stakeID];
        require(_amount > 0, "withdraw: zero amount");
        require(activeStake.amount >= _amount, "withdraw: not good");
        uint256 withdrawCount = user.withdrawStakesCount;
        uint256 taxReduction = getActiveStakeTaxReduction(_user, _stakeID);
        bool isAutoCompound = isStakeAutoPool(_user,_stakeID);
        user.withdrawnStakes[withdrawCount].amount = _amount;
        user.withdrawnStakes[withdrawCount].taxReduction = taxReduction;
        user.withdrawnStakes[withdrawCount].endTime = block.timestamp;
        user.withdrawnStakes[withdrawCount].isAutoPool = isAutoCompound;
        user.withdrawStakesCount++;
        activeStake.amount -= _amount;
        if(isAutoCompound){
            user.totalStakedAutoCompound -= _amount;
        }else{
            user.totalStakedDefault -= _amount;
        }

    }

    function utilizeWithdrawnStake(address _user, uint256 _amount, uint256 _stakeID) onlyDogPoundManager external {
        UserInfo storage user = userInfo[_user];
        WithdrawnStakeInfo storage withdrawnStake = user.withdrawnStakes[_stakeID];
        require(withdrawnStake.amount >= _amount);
        user.withdrawnStakes[_stakeID].amount -= _amount;
    }

    function getUserActiveStakes(address _user) public view returns (StakeInfoView[] memory){
        UserInfo storage user = userInfo[_user];
        StakeInfoView[] memory stakes = new StakeInfoView[](user.activeStakesCount);
        for (uint256 i=0; i < user.activeStakesCount; i++){
            stakes[i] = StakeInfoView({
                stakeID : i,
                taxReduction:getActiveStakeTaxReduction(_user,i),
                amount : user.activeStakes[i].amount,
                startTime : user.activeStakes[i].startTime,
                isAutoPool : user.activeStakes[i].isAutoPool
            });
        }
        return stakes;
    }


    function getUserWithdrawnStakes(address _user) public view returns (WithdrawnStakeInfoView[] memory){
        UserInfo storage user = userInfo[_user];
        WithdrawnStakeInfoView[] memory stakes = new WithdrawnStakeInfoView[](user.withdrawStakesCount);
        for (uint256 i=0; i < user.withdrawStakesCount; i++){
            stakes[i] = WithdrawnStakeInfoView({
                stakeID : i,
                amount : user.withdrawnStakes[i].amount,
                taxReduction : user.withdrawnStakes[i].taxReduction,
                endTime : user.withdrawnStakes[i].endTime,
                isAutoPool : user.withdrawnStakes[i].isAutoPool
            });
        }
        return stakes;
    }

    function getActiveStakeTaxReduction(address _user, uint256 _stakeID) public view returns (uint256){
        StakeInfo storage activeStake = userInfo[_user].activeStakes[_stakeID];
        uint256 relief = reliefPerDay;
        if (activeStake.isAutoPool){
            relief = reliefPerDay + reliefPerDayExtra;
        }
        uint256 taxReduction = ((block.timestamp - activeStake.startTime) / 24 hours) * relief;
        return taxReduction;

    }

    function getWithdrawnStakeTaxReduction(address _user, uint256 _stakeID) public view returns (uint256){
        UserInfo storage user = userInfo[_user];
        return user.withdrawnStakes[_stakeID].taxReduction;
    }

    function getUserActiveStake(address _user, uint256 _stakeID) external view returns (StakeInfo memory){
        return userInfo[_user].activeStakes[_stakeID];

    }
    
    function changeReliefValues(uint256 relief1,uint256 relief2) external onlyOwner{
        require(relief1+relief2 < 1000);
        reliefPerDay = relief1;
        reliefPerDayExtra = relief2;
    }

    function getUserWithdrawnStake(address _user, uint256 _stakeID) external view returns (WithdrawnStakeInfo memory){
        return userInfo[_user].withdrawnStakes[_stakeID];
    }

    function isStakeAutoPool(address _user, uint256 _stakeID) public view returns (bool){
        return userInfo[_user].activeStakes[_stakeID].isAutoPool;
    }

    function totalStaked(address _user) public view returns (uint256){
        return userInfo[_user].totalStakedDefault + userInfo[_user].totalStakedAutoCompound;
    }
    
    function setDogPoundManager(address _address) public onlyOwner {
        DogPoundManger = _address;
    }

}
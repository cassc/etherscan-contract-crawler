// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interface/IStakedToken.sol";
import "./library/StructLibrary.sol";

contract NewStake is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint128;

    using StructLibrary for StructLibrary.eachTransaction;
    using StructLibrary for StructLibrary.StakeTypeData;

    IStakedToken public stakedToken;

    string public name;
    string public symbol;
    address public ownerWallet;
    address public treasury;
    uint128 public totalStaked;
    uint128 public emergencyFees;
    uint128 public platformFee;
    uint128 public maxStakeLimit;


    bool public claimAndWithdrawFreeze;

    StructLibrary.StakeTypeData[] public stakeTypesList;

    mapping(address => mapping(uint128 => StructLibrary.eachTransaction)) public userStakesData;
    mapping(address => mapping(uint128 => StructLibrary.eachTransaction[])) public userAllStakesData;


    event Deposit(uint128 stakeAmount, uint128 stakeType, uint128 stakePeriod, uint256 time, uint128 poolTotalStaked);
    event Withdraw(address indexed user, uint128 stakeAmount, uint128 stakeType, uint128 rewardAmount, uint256 time, uint128 poolTotalStaked);
    event Compound(address indexed user, uint128 rewardAmount, uint128 stakeType, uint256 time, uint128 poolTotalStaked);
    event Claim(address indexed user, uint128 rewardAmount, uint128 stakeType, uint256 time);
    event AddStakeType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate);
    event UpdateStakeType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate);
    event DeleteStakeType(uint128 _stakeType);
    event UpdateStakeToken(address indexed newTokenAddr);
    event EmergencyWithdrawn(address indexed user, uint128 amount, uint128 stakeType, uint256 time, uint128 poolTotalStaked);
    event UpdateEmergencyFee(address indexed _stakeToken, uint128 oldFee, uint128 newFee);
    event UpdatePlatformFee(address indexed _stakeToken, uint128 oldFee, uint128 newFee);
    event UpdateOwnerWallet(address indexed _stakeToken, address indexed oldOwnerWallet, address indexed newOwnerWallet);
    event UpdateTreasuryWallet(address indexed _stakeToken, address indexed oldTreasuryWallet, address indexed newTreasuryWallet);



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _ownerWallet, address _stakedToken, 
                        uint128 _stakePeriod, uint128 _depositFees, 
                        uint128 _withdrawlsFees, uint128 _rewardRate, uint128 _emergencyFees, uint128 _platformFee, address _treasury, uint128 _maxStakeLimit) 
                        public initializer {
        require(_treasury != address(0), "TREASURY_WALLET_CANT_BE_NULL_ADDRESS");
        require(_emergencyFees > 0, "EMERGENCY_FEES_CANT_BE_ZERO");
        require(_platformFee > 0, "PLATFORM_FEE_CANT_BE_NULL");
        require(_ownerWallet !=address(0), "OWNER_WALLET_CANT_BE_NULL_ADDRESS");
        require(_stakedToken !=address(0), "TOKEN_ADDRESS_CANT_BE_NULL_ADDRESS");
        require(_depositFees < 10000 && _withdrawlsFees < 10000, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100%");             // FOR DEPOSIT AND WITHDRAWL FESS
                                                                                                                        // 0.01 % -----> input is 1
                                                                                                                        // 0.1% ------> input is 10
                                                                                                                        // 1% -------> input is 100
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        __Ownable_init();

        stakedToken = IStakedToken(_stakedToken);
        ownerWallet = _ownerWallet;    
        name = IStakedToken(_stakedToken).name();
        symbol = IStakedToken(_stakedToken).symbol();
        emergencyFees = _emergencyFees;
        platformFee = _platformFee;
        treasury = _treasury;
        maxStakeLimit = _maxStakeLimit;

        stakeTypesList.push(StructLibrary.StakeTypeData(0,_stakePeriod,_depositFees,_withdrawlsFees,_rewardRate,0, true));

    }
    
    function deposit(address user,uint128 _amount, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128 emitAmount, uint128 _period, uint128 _totalPoolStaked) {
        require(_amount>0, "STAKE_MORE_THAN_ZERO");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        transferPlatformFee(treasury, user, uint128(msg.value));

        StructLibrary.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        require(stakeType.isActive, "POOL_DISABLED");
        StructLibrary.eachTransaction storage stakes = userStakesData[user][_stakeType];
        {
        uint128 limitLeft;
        if(stakes.stakeAmount > 0 && !stakes.accumulated) {
            if(maxStakeLimit > stakes.stakeAmount) limitLeft = maxStakeLimit - stakes.stakeAmount;
            require(limitLeft > 0,"MAX_STAKE_LIMIT_REACHED");
            if(_amount > limitLeft) _amount = limitLeft;
        } else {
            if(userAllStakesData[user][_stakeType].length > 0) {
                uint128 stakedAmount;
                for(uint128 i=0; i < uint128(userAllStakesData[user][_stakeType].length); ++i) {
                    stakedAmount += userAllStakesData[user][_stakeType][i].stakeAmount;
                }
                if(maxStakeLimit > stakedAmount) limitLeft = maxStakeLimit - stakedAmount;
                require(limitLeft > 0,"MAX_STAKE_LIMIT_REACHED");
                if(_amount > limitLeft) _amount = limitLeft;
            } else {
                if(_amount > maxStakeLimit) _amount = maxStakeLimit;
            }
        }
        }

        _period = stakeType.stakePeriod;
        uint128 fees;
        uint128 actualAmount = _amount;

        if(stakeType.depositFees !=0) {
            fees = _amount * stakeType.depositFees *100 / 1000000;
            actualAmount = _amount - fees;
        }

        if(fees > 0) stakedToken.transferFrom(user, treasury, fees);
        uint128 beforeAmount = uint128(stakedToken.balanceOf(address(this)));
        stakedToken.transferFrom(user, address(this), actualAmount);

        uint128 realAmount = uint128(stakedToken.balanceOf(address(this))) - beforeAmount;

        if(stakes.stakeAmount > 0 && !stakes.accumulated) {
            stakes.accumulated = true;
            userAllStakesData[user][_stakeType].push(StructLibrary.eachTransaction(stakes.stakeAmount, stakes.depositTime, stakes.fullWithdrawlTime, stakes.lastClaimTime, true));
            userAllStakesData[user][_stakeType].push(StructLibrary.eachTransaction(realAmount, uint128(block.timestamp), uint128(uint128(block.timestamp).add(stakeType.stakePeriod * 60)), uint128(block.timestamp), true));

            stakeType.totalStakedIn = uint128(stakeType.totalStakedIn.add(realAmount));
            // userTotalPerPool[user][_stakeType] +=  realAmount;
            totalStaked += realAmount;
            emit Deposit(realAmount, _stakeType, stakeType.stakePeriod, block.timestamp, stakeType.totalStakedIn);
            emitAmount = realAmount;
            _totalPoolStaked = stakeType.totalStakedIn;
        } else {
            stakes.accumulated = true;
            userAllStakesData[user][_stakeType].push(StructLibrary.eachTransaction(realAmount, uint128(block.timestamp), uint128(uint128(block.timestamp).add(stakeType.stakePeriod * 60)), uint128(block.timestamp), true));
            
            stakeType.totalStakedIn = uint128(stakeType.totalStakedIn.add(realAmount));
            // userTotalPerPool[user][_stakeType] +=  realAmount;
            totalStaked += realAmount;
            emit Deposit(realAmount, _stakeType, stakeType.stakePeriod, block.timestamp, stakeType.totalStakedIn);
            emitAmount = realAmount;
            _totalPoolStaked = stakeType.totalStakedIn;
        }
    }

    function compound(address user, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128, uint128, uint128) {
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        StructLibrary.eachTransaction storage stakes = userStakesData[user][_stakeType];
        // require(stakes.stakeAmount > 0, "NOTHING_AT_STAKE");

        transferPlatformFee(treasury, user, uint128(msg.value));

        StructLibrary.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        // require(stakeType.isActive, "POOL_DISABLED");
    
        uint128 totalRewardTillNow;
        
        uint128 stakeTimeTillNow;
        // uint128 totalStakes = uint128(userAllStakesData[user][_stakeType].length);

        
        if(!stakes.accumulated) {
            require(stakes.stakeAmount > 0, "NOTHING_AT_STAKE");
            uint128 actualAmount = stakes.stakeAmount;

            if(uint128(block.timestamp) < stakes.fullWithdrawlTime) {
                stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;
                totalRewardTillNow = rewardCalculation(actualAmount, _stakeType, stakeTimeTillNow); 
                stakes.lastClaimTime = uint128(block.timestamp);
            } else {
                if(stakeType.stakePeriod == 0) {
                    stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;
                    stakes.lastClaimTime = uint128(block.timestamp);
                    }
                else {
                    stakeTimeTillNow = stakes.fullWithdrawlTime - stakes.lastClaimTime;
                    stakes.lastClaimTime = stakes.fullWithdrawlTime;
                    }

                if(stakeTimeTillNow > 0)
                totalRewardTillNow = rewardCalculation(actualAmount, _stakeType, stakeTimeTillNow);                
            }

            uint128 beforeAmount = uint128(stakedToken.balanceOf(address(this)));

            if(totalRewardTillNow > 0)
            claimReward(address(this), totalRewardTillNow);
    
            uint128 realAmount = uint128(stakedToken.balanceOf(address(this))) - beforeAmount;

            stakes.stakeAmount += realAmount;

            stakeType.totalStakedIn +=  realAmount;
            totalStaked += realAmount;
            emit Compound(user, realAmount, _stakeType, block.timestamp, stakeType.totalStakedIn);
            return (realAmount, stakeType.stakePeriod, stakeType.totalStakedIn);
        } else {
                require(uint128(userAllStakesData[user][_stakeType].length) > 0, "NOTHING_AT_STAKE");
                uint128 totalCompounded;
                for(uint128 i=0; i<uint128(userAllStakesData[user][_stakeType].length); ++i) {

                    if(userAllStakesData[user][_stakeType][i].stakeAmount == 0) continue;

                    if(uint128(block.timestamp) < userAllStakesData[user][_stakeType][i].fullWithdrawlTime) {
                        stakeTimeTillNow = uint128(block.timestamp) - userAllStakesData[user][_stakeType][i].lastClaimTime;
                        totalRewardTillNow = rewardCalculation(userAllStakesData[user][_stakeType][i].stakeAmount, _stakeType, stakeTimeTillNow); 
                        userAllStakesData[user][_stakeType][i].lastClaimTime = uint128(block.timestamp);
                    } else {
                        if(stakeType.stakePeriod == 0) {
                            stakeTimeTillNow = uint128(block.timestamp) - userAllStakesData[user][_stakeType][i].lastClaimTime;
                            userAllStakesData[user][_stakeType][i].lastClaimTime = uint128(block.timestamp);
                        }
                        else {
                            stakeTimeTillNow = userAllStakesData[user][_stakeType][i].fullWithdrawlTime - userAllStakesData[user][_stakeType][i].lastClaimTime;
                            userAllStakesData[user][_stakeType][i].lastClaimTime = userAllStakesData[user][_stakeType][i].fullWithdrawlTime;
                        }

                        if(stakeTimeTillNow > 0)
                        totalRewardTillNow = rewardCalculation(userAllStakesData[user][_stakeType][i].stakeAmount, _stakeType, stakeTimeTillNow);                
                    }

                    uint128 beforeAmount = uint128(stakedToken.balanceOf(address(this)));

                    if(totalRewardTillNow > 0) claimReward(address(this), totalRewardTillNow);

                    uint128 realAmount = uint128(stakedToken.balanceOf(address(this))) - beforeAmount;

                    userAllStakesData[user][_stakeType][i].stakeAmount += realAmount;
                    totalCompounded += realAmount;
                    stakeType.totalStakedIn +=  realAmount;
                    totalStaked += realAmount;
                    
                }
            emit Compound(user, totalCompounded, _stakeType, block.timestamp, stakeType.totalStakedIn);
            return (totalCompounded, stakeType.stakePeriod, stakeType.totalStakedIn);

        }

            
    }

    function withdraw(address user, uint128 _amount, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128, uint128, uint128) {

        StructLibrary.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        // require(stakeType.isActive, "POOL_DISABLED");

        require(_amount > 0, "WITHDRAW_MORE_THAN_ZERO");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        StructLibrary.eachTransaction storage stakes = userStakesData[user][_stakeType];
        
        transferPlatformFee(treasury, user, uint128(msg.value));

        uint128 totalStakes = uint128(userAllStakesData[user][_stakeType].length);


        if(!stakes.accumulated) {

            require(_amount <= stakes.stakeAmount, "CANT_WITHDRAW_MORE_THAN_STAKED");

            require(uint128(block.timestamp) > stakes.fullWithdrawlTime, "CANT_UNSTAKE_BEFORE_LOCKUP_TIME");

            uint128 stakeTimeTillNow;
            if(stakeType.stakePeriod == 0) {
                stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;
                stakes.lastClaimTime = uint128(block.timestamp);

                }
            else {
                stakeTimeTillNow = stakes.fullWithdrawlTime - stakes.lastClaimTime;
                stakes.lastClaimTime = stakes.fullWithdrawlTime;
                }
            uint128 rewardTillNow;
            if(stakeTimeTillNow > 0) rewardTillNow = rewardCalculation(stakes.stakeAmount, _stakeType, stakeTimeTillNow);

            
            uint128 actualAmount = _amount;

            stakes.stakeAmount -= actualAmount;
            if(stakes.stakeAmount == 0) stakes.accumulated = true;
            stakeType.totalStakedIn -=  actualAmount;
            totalStaked -= actualAmount;
            bool success;
        {
            uint128 _withdrawlFees = stakeType.withdrawlFees;
            uint128 fees;

            if(_withdrawlFees !=0) {
                fees = _amount * _withdrawlFees *100 / 1000000;
                actualAmount = _amount - fees;
            }
            if(rewardTillNow > 0) claimReward(user, rewardTillNow);
            
            if(fees > 0)
            {
                success = stakedToken.transfer(treasury, fees);
                if(!success) revert();
            }
        }
            if(actualAmount > 0) {
                success = stakedToken.transfer(user, actualAmount);
                if(!success) revert();
            }
        
            emit Withdraw(user, actualAmount, _stakeType, rewardTillNow, block.timestamp, stakeType.totalStakedIn);
            return (actualAmount, stakeType.stakePeriod, stakeType.totalStakedIn);
        } else {
            require(uint128(block.timestamp) > userAllStakesData[user][_stakeType][0].fullWithdrawlTime, "CANT_UNSTAKE_BEFORE_LOCKUP_TIME");
            // require(_amount <= userAllStakesData[user][_stakeType][0].stakeAmount, "WITHDRAW_LESS_AMOUNT");
            uint128 unlockedAmount;
        
            uint128 rewardTillNow;
            for(uint128 i=0; i<totalStakes; ++i) {
                uint128 totalStakeTimeTillNow;
                {
                // uint128 calcAmount;
                if(userAllStakesData[user][_stakeType][i].stakeAmount == 0) continue;
                // time check for each deposits
                if(_amount <= userAllStakesData[user][_stakeType][i].stakeAmount) {
                    if(uint128(block.timestamp) < userAllStakesData[user][_stakeType][i].fullWithdrawlTime) break;
                    unlockedAmount += _amount;
                    // calcAmount = _amount;
                    userAllStakesData[user][_stakeType][i].stakeAmount -= _amount;
                    totalStakeTimeTillNow += userAllStakesData[user][_stakeType][i].fullWithdrawlTime - userAllStakesData[user][_stakeType][i].lastClaimTime;
                    if(unlockedAmount > 0 && totalStakeTimeTillNow > 0) rewardTillNow += rewardCalculation(_amount, _stakeType, totalStakeTimeTillNow);
                    // userAllStakesData[user][_stakeType][i].lastClaimTime = userAllStakesData[user][_stakeType][i].fullWithdrawlTime;
                    break;

                } else {
                    if(uint128(block.timestamp) < userAllStakesData[user][_stakeType][i].fullWithdrawlTime) break;
                    unlockedAmount += userAllStakesData[user][_stakeType][i].stakeAmount;
                    _amount -= userAllStakesData[user][_stakeType][i].stakeAmount;
                    // calcAmount = userAllStakesData[user][_stakeType][i].stakeAmount;
                    totalStakeTimeTillNow += userAllStakesData[user][_stakeType][i].fullWithdrawlTime - userAllStakesData[user][_stakeType][i].lastClaimTime;
                    if(unlockedAmount > 0 && totalStakeTimeTillNow > 0) rewardTillNow += rewardCalculation(userAllStakesData[user][_stakeType][i].stakeAmount, _stakeType, totalStakeTimeTillNow);
                    userAllStakesData[user][_stakeType][i].stakeAmount = 0;
                    
                    // userAllStakesData[user][_stakeType][i].lastClaimTime = userAllStakesData[user][_stakeType][i].fullWithdrawlTime;
                }   
                }
            }

            // if(unlockedAmount > 0 && totalStakeTimeTillNow > 0) {
            // rewardTillNow = rewardCalculation(unlockedAmount, _stakeType, totalStakeTimeTillNow);
            if(rewardTillNow > 0) claimReward(user, rewardTillNow);
            // }
        
            stakeType.totalStakedIn -=  unlockedAmount;
            totalStaked -= unlockedAmount;

            
            uint128 actualAmount = unlockedAmount;
            // bool success;
        
            uint128 _withdrawlFees = stakeType.withdrawlFees;
            {
            uint128 fees;
            if(_withdrawlFees !=0) {
                fees = unlockedAmount * _withdrawlFees *100 / 1000000;
                actualAmount = unlockedAmount - fees;
            }
        
            if(fees > 0){
                stakedToken.transfer(treasury, fees);
                // if(!success) revert();
            }
            }
            if(actualAmount > 0) {
                stakedToken.transfer(user, actualAmount);
                // if(!success) revert();
            }
        
            emit Withdraw(user, actualAmount, _stakeType, rewardTillNow, block.timestamp, stakeType.totalStakedIn);
            return (actualAmount, stakeType.stakePeriod, stakeType.totalStakedIn);
        }

        
    }

    function claim(address user, uint128 _stakeType) external payable nonReentrant onlyOwner returns(uint128, uint128) {
        // require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");

        StructLibrary.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        // require(stakeType.isActive, "POOL_DISABLED");

        require(stakeType.stakePeriod == 0, "CANT_CLAIM_FOR_THIS_TYPE");

        StructLibrary.eachTransaction storage stakes = userStakesData[user][_stakeType];
        require(uint128(block.timestamp) > stakes.fullWithdrawlTime, "WAIT_TO_CLAIM");
        uint128 totalRewardTillNow;
        uint128 actualAmount = stakes.stakeAmount;
        require(actualAmount > 0, "NOTHING_AT_STAKE");

        transferPlatformFee(treasury, user, uint128(msg.value));

        uint128 stakeTimeTillNow;
    
        stakeTimeTillNow = uint128(block.timestamp) - stakes.lastClaimTime;

        if(stakeTimeTillNow > 0) totalRewardTillNow = rewardCalculation(actualAmount, _stakeType, stakeTimeTillNow); 
        stakes.lastClaimTime = uint128(block.timestamp);
            
           
        if(totalRewardTillNow > 0)
        claimReward(user, totalRewardTillNow);

        emit Claim(user, totalRewardTillNow, _stakeType, block.timestamp);
        return (totalRewardTillNow, stakeType.stakePeriod);
    }

    function rewardCalculation(uint128 _amount, uint128 _stakeType, uint128 _time) public view returns(uint128) {
        StructLibrary.StakeTypeData memory stakeType = stakeTypesList[_stakeType];

        require(_amount > 0, "AMOUNT_SHOULD_BE_GREATER_THAN_ZERO");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        require(_time > 0, "INVALID_TIME");
        uint128 rate = stakeType.rewardRate;
        uint128 interest = (_amount * rate * _time) / (100 * 365 days);
        return interest;
    }

    function claimReward(address to, uint128 _rewardAmount) private {
        require(to != address(0), "INVALID_CLAIMER");
        require(_rewardAmount > 0, "INVALID_REWARD_AMOUNT");
        uint128 ownerBal = uint128(stakedToken.balanceOf(ownerWallet));
        if(_rewardAmount > ownerBal) claimAndWithdrawFreeze = true;
        require(!claimAndWithdrawFreeze, "CLAIM_AND_WITHDRAW_FREEZED");
        bool success = stakedToken.transferFrom(ownerWallet, to, _rewardAmount);
        if(!success) revert();
    }
    // FOR DEPOSIT AND WITHDRAWL FEES
    // 0.01 % -----> input is 1
    // 0.1% ------> input is 10
    // 1% -------> input is 100
    function addStakedType(uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate) external onlyOwner returns(uint128){
        // require(!stakeTypeExist[_stakeType], "STAKE_TYPE_EXISTS");
        require(_depositFees < 10000 && _withdrawlFees < 10000, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        // stakeTypeExist[_stakeType] = true;
        uint128 poolType = uint128(stakeTypesList.length);

        stakeTypesList.push(StructLibrary.StakeTypeData(poolType,_stakePeriod,_depositFees,_withdrawlFees,_rewardRate,0, true));

        emit AddStakeType(poolType, _stakePeriod, _depositFees, _withdrawlFees, _rewardRate);
        return poolType;
    }
    // FOR DEPOSIT AND WITHDRAWL FESS
    // 0.01 % -----> input is 1
    // 0.1% ------> input is 10
    // 1% -------> input is 100
    function updateStakeType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawlFees, uint128 _rewardRate) external onlyOwner {
        // require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        require(_depositFees < 10000 && _withdrawlFees < 10000, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");

        StructLibrary.StakeTypeData storage stakeType = stakeTypesList[_stakeType];

        stakeType.stakeType = _stakeType;
        stakeType.stakePeriod = _stakePeriod;
        stakeType.depositFees = _depositFees;
        stakeType.withdrawlFees = _withdrawlFees;
        stakeType.rewardRate = _rewardRate;

        emit UpdateStakeType(_stakeType, _stakePeriod, _depositFees, _withdrawlFees, _rewardRate);
    }

    function getPoolData(uint128 _stakeType) external view returns(StructLibrary.StakeTypeData memory) {
        // require(stakeTypeExist[_stakeType], "INVALID_STAKE_TYPE");
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        require(stakeTypesList[_stakeType].isActive, "POOL_DISABLED");

        return stakeTypesList[_stakeType];
    }

    function deleteStakeType(uint128 _stakeType) external onlyOwner returns(bool) {
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        // require(stakeTypesList[_stakeType].totalStakedIn == 0, "CANT_DELETE");

        stakeTypesList[_stakeType].isActive = false;

        emit DeleteStakeType(_stakeType);
        return false;
    }    

    function getPoolLength() external view returns(uint128) {
        return uint128(stakeTypesList.length);
    }

    function emergencyWithdraw(address user, uint128 _stakeType) external payable onlyOwner returns(uint128, uint128, uint128){
        require(_stakeType < uint128(stakeTypesList.length), "INVALID_STAKE_TYPE");
        StructLibrary.StakeTypeData storage stakeType = stakeTypesList[_stakeType];
        StructLibrary.eachTransaction storage stakes = userStakesData[user][_stakeType];
        transferPlatformFee(treasury, user, uint128(msg.value));

        uint128 fees;
        bool success;

        if(!stakes.accumulated) {

        uint128 amount = stakes.stakeAmount;
        require( amount > 0, "NOTHING_TO_WITHDRAW");

        stakes.stakeAmount = 0;
        stakes.lastClaimTime = uint128(block.timestamp);
        stakes.accumulated = true;

        stakeType.totalStakedIn -=  amount;
        totalStaked -= amount;

        fees = (amount * emergencyFees) / 100 ;
        if(fees > 0 ) {
            success = stakedToken.transfer(treasury, fees);
            if(!success) revert();
            amount -= fees;
        }

        success = stakedToken.transfer(user, amount);
        if(!success) revert();

        emit EmergencyWithdrawn(user, amount, _stakeType, block.timestamp, stakeType.totalStakedIn);
        return (amount, stakeType.stakePeriod, stakeType.totalStakedIn);

        } else {
            uint128 totalStakes = uint128(userAllStakesData[user][_stakeType].length);
            uint128 _amount;
            for(uint128 i =0; i<totalStakes; ++i) {
                if(userAllStakesData[user][_stakeType][i].stakeAmount == 0) continue;

               _amount += userAllStakesData[user][_stakeType][i].stakeAmount;
               userAllStakesData[user][_stakeType][i].stakeAmount = 0;
               userAllStakesData[user][_stakeType][i].lastClaimTime = uint128(block.timestamp);
            }

            stakeType.totalStakedIn -=  _amount;
            totalStaked -= _amount;

            fees = (_amount * emergencyFees) / 100 ;
            if(fees > 0 ) {
                success = stakedToken.transfer(treasury, fees);
                if(!success) revert();
                _amount -= fees;
            }
            if(_amount > 0) {
            success = stakedToken.transfer(user, _amount);
            if(!success) revert();
            }

            emit EmergencyWithdrawn(user, _amount, _stakeType, block.timestamp, stakeType.totalStakedIn);
            return (_amount, stakeType.stakePeriod, stakeType.totalStakedIn);
        }
    }

    function updateEmergencyFees(uint128 newFees) external onlyOwner {
        require(newFees > 0, "EMERGENCY_FEES_CANT_BE_ZERO");
        require(newFees != emergencyFees, "CANT_SET SAME_FEES");
        uint128 oldFee = emergencyFees;
        emergencyFees = newFees;
        
        emit UpdateEmergencyFee(address(stakedToken), oldFee, newFees);
    }

    function transferPlatformFee(address to, address _user,  uint128 _value) private {
        require(to != address(0), "CANT_SEND_TO_NULL_ADDRESS");
        require(_value >= platformFee, "INCREASE_PLATFORM_FEE");
        (bool success, ) = payable(to).call{value:platformFee}("");
        require(success, "PLATFORM_FEE_TRANSFER_FAILED");
        uint128 remainingEth = _value - platformFee;
        if (remainingEth > 0) {
            (success,) = payable(_user).call{value: remainingEth}("");
            require(success, "REFUND_REMAINING_ETHER_SENT_FAILED");
        }
    }

    function updatePlatformFee(uint128 newFee) external onlyOwner {
        require(newFee > 0, "PLATFORM_FEE_CANT_BE_NULL");
        require(newFee != platformFee, "PLATFORM_FEE_CANT_BE_SAME");

        uint128 oldFee = platformFee;
        platformFee = newFee;

        emit UpdatePlatformFee(address(stakedToken), oldFee, newFee);
    }

    function updateOwnerWallet(address newOwnerWallet) external onlyOwner {
        require(newOwnerWallet != address(0), "OWNER_CANT_BE_ZERO_ADDRESS");
        require(newOwnerWallet != ownerWallet, "ALREADY_SET_THIS OWNER");

        address oldOwnerWallet = ownerWallet;
        ownerWallet = newOwnerWallet;

        emit UpdateOwnerWallet(address(stakedToken), oldOwnerWallet, newOwnerWallet);
    }

    function updateTreasuryWallet(address newTreasuryWallet) external onlyOwner {
        require(newTreasuryWallet != address(0), "TREASURY_WALLET_CANT_BE_NULL");
        require(newTreasuryWallet != treasury, "ALREADY_SET_THS_WALLET");

        address oldTreasuryWallet = ownerWallet;
        treasury = newTreasuryWallet;

        emit UpdateTreasuryWallet(address(stakedToken), oldTreasuryWallet, newTreasuryWallet);
    }

    function updateStakeLimit(uint128 _newLimit) external onlyOwner {
        require(maxStakeLimit != _newLimit);
        maxStakeLimit = _newLimit;

    }

    function userUnlockAmount(address user, uint128 _stakeType) external view returns(uint128 unlockAmount, uint128 lockAmount) {
        uint128 totalStakes = uint128(userAllStakesData[user][_stakeType].length);
    
        for(uint128 i=0; i < totalStakes; ++i) {

            if(userAllStakesData[user][_stakeType][i].stakeAmount == 0) continue;

            if(uint128(block.timestamp) > userAllStakesData[user][_stakeType][i].fullWithdrawlTime) unlockAmount += userAllStakesData[user][_stakeType][i].stakeAmount;
            else lockAmount += userAllStakesData[user][_stakeType][i].stakeAmount;
            
        }
    }

    function userTotalTxPerPool(address user, uint128 _stakeType) external view returns(StructLibrary.eachTransaction[] memory userAllStakes, uint128 len) {
        len = uint128(userAllStakesData[user][_stakeType].length);
        userAllStakes = new StructLibrary.eachTransaction[](uint128(userAllStakesData[user][_stakeType].length));
        for(uint128 i=0; i < uint128(userAllStakesData[user][_stakeType].length); i++) {
            userAllStakes[i] = userAllStakesData[user][_stakeType][i];
        }
        return (userAllStakes, len);
    }
}
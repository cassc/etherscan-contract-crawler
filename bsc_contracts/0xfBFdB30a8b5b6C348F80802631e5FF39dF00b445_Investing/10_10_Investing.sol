// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Investing is OwnableUpgradeable, PausableUpgradeable {
    address public investTokenAddress;
    uint8 public investTokenDecimals;
    uint public minimumInvestAmount;
    uint public endTimePeriod;
    uint public rewardPercent;
    uint public depositFeePercent;
    uint public withdrawFeePercent;

    uint public referRewardPercent;
    uint public ownerInvestSharePercent;
    uint public usersInvestRewardsInsurancePercent;

    //amount of investment that owner can withdraw
    uint public ownerInvestShareAmount;
    uint public allUsersInviteRewardAmount;


    //history variables
    uint public historyInvestAmount;
    uint public historyDepositByOwner;
    uint public historyClaimedAllRewards;
    uint public historyClaimedInviteRewards;
    uint public historyClaimedOwnerInviteRewards;
    uint public historyClaimedInvestRewards;
    uint public historyWithdrawOwnerShare;
    uint public historyWithdrawFreeBalance;
    uint public historyWithdrawEmergency;

    //events
    event InvestEvent(uint amount, address user, uint time);
    event WithdrawUserReward(uint amount, address user, uint time);
    event WithdrawOwnerShare(uint amount, address user, uint time);
    event WithdrawFreeBalance(uint amount, address user, uint time);
    event WithdrawEmergency(uint amount, address user, uint time);
    event DepositByOwner(uint amount, address user, uint time);

    struct InvestInfo {
        address refer;
        uint totalInvestmentAmount;
        uint totalInvestReward;
        uint remainedInvestReward;
        uint investmentStartTime;
        uint investmentEndTime;
        uint lastClaimedInvestRewardTime;
        bool isActive;
    }

    address[] public users;

    mapping(address => InvestInfo) public investInfo;
    mapping(address => uint) public inviteRewards;
    mapping(address => uint) public allInviteRewards;
    mapping(address => uint) public userClaimedRewards;
    mapping(address => uint) public previousUnclaimedInvestReward;
    mapping(address => bool) public isRegistered;
    mapping(address => bool) public freezed;

    event Invest(
        address token,
        address user,
        address refer,
        address amount,
        uint startTime,
        uint endTime
    );

    //initialize function is constructor for upgradeable smart contract
    function initialize(
        address _investTokenAddress,
        uint8 _investCurrencyDecimals
    ) public initializer {
        __Ownable_init();
        investTokenAddress = _investTokenAddress;
        _investCurrencyDecimals = _investCurrencyDecimals;
        minimumInvestAmount = 100e18;
        endTimePeriod = 36 * 30 days;
        rewardPercent = 180;
        depositFeePercent = 5;
        withdrawFeePercent = 5;

        referRewardPercent = 30;
        ownerInvestSharePercent = 65;
        usersInvestRewardsInsurancePercent = 5;
    }

    /*--------------------------------- User Call functions --------------------------------*/
    /*----------------------------------------------------------------------------------*/

    function totalUsers() public view returns (address[] memory) {
        return users;
    }

    function refer(address user) public view returns (address) {
        return investInfo[user].refer;
    }

    function totalInvestmentAmount(address user) public view returns (uint) {
        return investInfo[user].totalInvestmentAmount;
    }

    function totalInvestReward(address user) public view returns (uint) {
        return investInfo[user].totalInvestReward;
    }

    function remainedInvestReward(address user) public view returns (uint) {
        return investInfo[user].remainedInvestReward;
    }

    function investmentStartTime(address user) public view returns (uint) {
        return investInfo[user].investmentStartTime;
    }

    function investmentEndTime(address user) public view returns (uint) {
        return investInfo[user].investmentEndTime;
    }


    function lastClaimedInvestRewardTime(
        address user
    ) public view returns (uint) {
        return investInfo[user].lastClaimedInvestRewardTime;
    }

    function isActive(address user) public view returns (bool) {
        return investInfo[user].isActive;
    }

    function getTotalInvestRewardsUntillNow(
        address _user
    ) public view returns (uint256) {
        uint allInvestmentPeriod = investInfo[_user].investmentEndTime -
            investInfo[_user].investmentStartTime;
        uint startUntillNowPeriod = block.timestamp -
            investInfo[_user].investmentStartTime;
        if (block.timestamp >= investInfo[_user].investmentEndTime) {
            return investInfo[_user].totalInvestReward;
        } else {
            return
                (investInfo[_user].totalInvestReward * startUntillNowPeriod) /
                allInvestmentPeriod;
        }
    }

    function getTotalInvestRewardsUntillTime(
        address _user,
        uint _time
    ) public view returns (uint256) {
        uint allInvestmentPeriod = investInfo[_user].investmentEndTime -
            investInfo[_user].investmentStartTime;
        uint startUntillNowPeriod = _time -
            investInfo[_user].investmentStartTime;
        if (block.timestamp >= investInfo[_user].investmentEndTime) {
            return investInfo[_user].totalInvestReward;
        } else {
            return
                (investInfo[_user].totalInvestReward * startUntillNowPeriod) /
                allInvestmentPeriod;
        }
    }

    function getUnclaimedRewards(address _user) public view returns (uint256) {
        uint256 unClaimedRewards = 0;

        if (
            investInfo[_user].totalInvestmentAmount > 0
        ) {
            if (
                allInviteRewards[_user] +
                getTotalInvestRewardsUntillNow(_user) <
                investInfo[_user].totalInvestReward
            ) {

                    if (block.timestamp < investInfo[_user].investmentEndTime) {
                        uint256 allRemainPeriod = investInfo[_user].investmentEndTime -
                            investInfo[_user].lastClaimedInvestRewardTime;
                        uint256 unClaimedPeriod = block.timestamp -
                            investInfo[_user].lastClaimedInvestRewardTime;
                        uint256 unClaimedAmount = (investInfo[_user]
                            .remainedInvestReward * unClaimedPeriod) / allRemainPeriod;
                        unClaimedRewards += unClaimedAmount;
                    } else {
                        unClaimedRewards += investInfo[_user].remainedInvestReward;
                    } 

            }else {
                uint allExtraRewards = allInviteRewards[_user] + getTotalInvestRewardsUntillNow(_user) - investInfo[_user].totalInvestReward;
                uint userUnClaimedRewards = 0;
                //calculate userUnClaimedRewards
                if (block.timestamp < investInfo[_user].investmentEndTime) {
                    uint256 allRemainPeriod = investInfo[_user].investmentEndTime -
                        investInfo[_user].lastClaimedInvestRewardTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        investInfo[_user].lastClaimedInvestRewardTime;
                    uint256 unClaimedAmount = (investInfo[_user]
                        .remainedInvestReward * unClaimedPeriod) / allRemainPeriod;
                    userUnClaimedRewards += unClaimedAmount;
                } else {
                    userUnClaimedRewards += investInfo[_user].remainedInvestReward;
                }
                //Now if user unclaimed reward is more than extra amount we show that extra amount for user
                if(userUnClaimedRewards > allExtraRewards){
                    unClaimedRewards = userUnClaimedRewards - allExtraRewards;
                }
            }
        }
        return unClaimedRewards;
    }

    function getClaimedRewards(address _user) public view returns (uint256) {
        uint256 allPeriod = investInfo[_user].investmentEndTime -
            investInfo[_user].investmentStartTime;
        uint256 claimedPeriod = investInfo[_user].lastClaimedInvestRewardTime -
            investInfo[_user].investmentStartTime;
        if (
            investInfo[_user].lastClaimedInvestRewardTime <=
            investInfo[_user].investmentEndTime
        ) {
            uint256 claimedRewards = (investInfo[_user].totalInvestReward *
                claimedPeriod) / allPeriod;
            return claimedRewards;
        } else {
            return investInfo[_user].totalInvestReward;
        }
    }

    function userAllRewards(address _user) public view returns (uint256) {
        uint unClaimedReward = getUnclaimedRewards(_user);
        uint inviteReward = inviteRewards[_user];
        return (unClaimedReward +
            inviteReward +
            previousUnclaimedInvestReward[_user]);
    }


    function getAllUsersUnclaimedRewardsUntillNow() public view returns (uint) {
        // uint timeAfterOneMonth = block.timestamp + 30 days;
        uint neededRewards = 0;
        for (uint i = 0; i < users.length; i++) {
            if (
                investInfo[users[i]].totalInvestmentAmount > 0
            ) {
                if (
                allInviteRewards[users[i]] +
                getTotalInvestRewardsUntillTime(users[i], block.timestamp) <
                investInfo[users[i]].totalInvestReward
                ) {
                        if (
                            block.timestamp < investInfo[users[i]].investmentEndTime
                        ) {
                            uint256 allRemainPeriod = investInfo[users[i]]
                                .investmentEndTime -
                                investInfo[users[i]].lastClaimedInvestRewardTime;
                            uint256 unClaimedPeriod = block.timestamp -
                                investInfo[users[i]].lastClaimedInvestRewardTime;
                            uint256 unClaimedAmount = (investInfo[users[i]]
                                .remainedInvestReward * unClaimedPeriod) /
                                allRemainPeriod;
                            neededRewards += unClaimedAmount;
                            neededRewards += previousUnclaimedInvestReward[users[i]];
                        } else {
                            neededRewards += investInfo[users[i]].remainedInvestReward;
                            neededRewards += previousUnclaimedInvestReward[users[i]];
                        }

                }else {
                uint allExtraRewards = allInviteRewards[users[i]] + getTotalInvestRewardsUntillTime(users[i], block.timestamp) - investInfo[users[i]].totalInvestReward;
                uint userUnClaimedRewards = 0;
                //calculate userUnClaimedRewards
                if (
                    block.timestamp < investInfo[users[i]].investmentEndTime
                ) {
                    uint256 allRemainPeriod = investInfo[users[i]]
                        .investmentEndTime -
                        investInfo[users[i]].lastClaimedInvestRewardTime;
                    uint256 unClaimedPeriod = block.timestamp -
                        investInfo[users[i]].lastClaimedInvestRewardTime;
                    uint256 unClaimedAmount = (investInfo[users[i]]
                        .remainedInvestReward * unClaimedPeriod) /
                        allRemainPeriod;
                    userUnClaimedRewards += unClaimedAmount;
                } else {
                    userUnClaimedRewards += investInfo[users[i]].remainedInvestReward;
                }
                if(userUnClaimedRewards > allExtraRewards){
                    neededRewards = userUnClaimedRewards - allExtraRewards;
                    neededRewards += previousUnclaimedInvestReward[users[i]];
                }
             }
           } 
        }

        return neededRewards;
    }


    function estimateOneMonthInvestRewards() public view returns (uint) {
        uint timeAfterOneMonth = block.timestamp + 30 days;
        uint neededRewards = 0;
        for (uint i = 0; i < users.length; i++) {
            if (
                investInfo[users[i]].totalInvestmentAmount > 0
            ) {
                if (
                allInviteRewards[users[i]] +
                getTotalInvestRewardsUntillTime(users[i], timeAfterOneMonth) <
                investInfo[users[i]].totalInvestReward
                ) {
                        if (
                            timeAfterOneMonth < investInfo[users[i]].investmentEndTime
                        ) {
                            uint256 allRemainPeriod = investInfo[users[i]]
                                .investmentEndTime -
                                investInfo[users[i]].lastClaimedInvestRewardTime;
                            uint256 unClaimedPeriod = timeAfterOneMonth -
                                investInfo[users[i]].lastClaimedInvestRewardTime;
                            uint256 unClaimedAmount = (investInfo[users[i]]
                                .remainedInvestReward * unClaimedPeriod) /
                                allRemainPeriod;
                            neededRewards += unClaimedAmount;
                            neededRewards += previousUnclaimedInvestReward[users[i]];
                        } else {
                            neededRewards += investInfo[users[i]].remainedInvestReward;
                            neededRewards += previousUnclaimedInvestReward[users[i]];
                        }

                }else {
                uint allExtraRewards = allInviteRewards[users[i]] + getTotalInvestRewardsUntillTime(users[i], timeAfterOneMonth) - investInfo[users[i]].totalInvestReward;
                uint userUnClaimedRewards = 0;
                //calculate userUnClaimedRewards
                if (
                    timeAfterOneMonth < investInfo[users[i]].investmentEndTime
                ) {
                    uint256 allRemainPeriod = investInfo[users[i]]
                        .investmentEndTime -
                        investInfo[users[i]].lastClaimedInvestRewardTime;
                    uint256 unClaimedPeriod = timeAfterOneMonth -
                        investInfo[users[i]].lastClaimedInvestRewardTime;
                    uint256 unClaimedAmount = (investInfo[users[i]]
                        .remainedInvestReward * unClaimedPeriod) /
                        allRemainPeriod;
                    userUnClaimedRewards += unClaimedAmount;
                } else {
                    userUnClaimedRewards += investInfo[users[i]].remainedInvestReward;
                }
                if(userUnClaimedRewards > allExtraRewards){
                    neededRewards = userUnClaimedRewards - allExtraRewards;
                    neededRewards += previousUnclaimedInvestReward[users[i]];
                }
             }
           } 
        }

        return neededRewards;
    }

    /*--------------------------------- Owner functions --------------------------------*/
    /*----------------------------------------------------------------------------------*/

    function freezing(address _user, bool status) public onlyOwner {
        freezed[_user] = status;
    }

    function pause() public onlyOwner {
        bool isPaused = paused();
        require(isPaused == false, "The contract is now paused");
        _pause();
    }

    function unpause() public onlyOwner {
        bool isPaused = paused();
        require(isPaused == true, "The contract is unpaused");
        _unpause();
    }

    function setInvestTokenAddress(
        address _investTokenAddress,
        uint8 _investTokenDecimals
    ) public onlyOwner {
        require(
            _investTokenAddress != address(0),
            "Invest currency address can not be zero address"
        );
        require(
            _investTokenDecimals > 0,
            "Invest currency decimals can not be zero"
        );
        investTokenAddress = _investTokenAddress;
        investTokenDecimals = _investTokenDecimals;
    }

    function setMinimumInvestAmount(
        uint _minimumInvestAmount
    ) public onlyOwner {
        require(
            _minimumInvestAmount > 0,
            "Minimum invest amount can not be zero"
        );
        minimumInvestAmount = _minimumInvestAmount;
    }

    function setEndTimePeriod(uint _endTimePeriod) public onlyOwner {
        require(_endTimePeriod > 0, "End time period can not be zero");
        endTimePeriod = _endTimePeriod;
    }

    function setRewardPercent(uint _rewardPercent) public onlyOwner {
        require(_rewardPercent > 0, "Reward percent can not be zero");
        rewardPercent = _rewardPercent;
    }

    function setReferOwnerInsurePercents(
        uint _referRewardPercent,
        uint _ownerInvestSharePercent,
        uint _usersInvestRewardsInsurancePercent
    ) public onlyOwner {
        require(
            _referRewardPercent +
            _ownerInvestSharePercent +
            _usersInvestRewardsInsurancePercent ==
            100,
            "total of this three percents in not 100"
        );
        referRewardPercent = _referRewardPercent;
        ownerInvestSharePercent = _ownerInvestSharePercent;
        usersInvestRewardsInsurancePercent = _usersInvestRewardsInsurancePercent;
    }

    function withdrawOwnerShareAmount(uint _amount) public onlyOwner {
        require(_amount <= ownerInvestShareAmount, "Your desired amount is more than owner share");
        ownerInvestShareAmount -= _amount;
        SafeERC20Upgradeable.safeTransfer(
        IERC20Upgradeable(investTokenAddress),
            msg.sender,
            _amount
        );
        //history
        historyWithdrawOwnerShare += _amount;
        emit WithdrawOwnerShare(_amount, msg.sender, block.timestamp);
    }

    /*--------------------------------- User Send functions --------------------------------*/
    /*----------------------------------------------------------------------------------*/

    function _addUser(address user) private {
        if (isRegistered[user] == false){
            isRegistered[user] = true;
            users.push(user);
        }
    }


    function _giveReferReward(address _refer, uint _referRewardAmount) private {
        if (_refer != address(0) && investInfo[_refer].isActive) {
            if (
                allInviteRewards[_refer] +
                    _referRewardAmount +
                    getTotalInvestRewardsUntillNow(_refer) >=
                investInfo[_refer].totalInvestReward
            ) {
                uint difference = allInviteRewards[_refer] +
                    _referRewardAmount +
                    getTotalInvestRewardsUntillNow(_refer) -
                    investInfo[_refer].totalInvestReward;
                inviteRewards[owner()] += difference;
                inviteRewards[_refer] += _referRewardAmount - difference;
                allInviteRewards[_refer] += _referRewardAmount - difference;
                allUsersInviteRewardAmount += _referRewardAmount;
                //deactiveate
                investInfo[_refer].isActive = false;
            } else {
                inviteRewards[_refer] += _referRewardAmount;
                allInviteRewards[_refer] += _referRewardAmount;
                allUsersInviteRewardAmount += _referRewardAmount;
            }
        } else {
            inviteRewards[owner()] += _referRewardAmount;
            allUsersInviteRewardAmount += _referRewardAmount;
        }
    }

    function invest(
        uint _investAmountByFee,
        uint _investAmount,
        address _refer
    ) public whenNotPaused {
        require(
            _investAmount >= minimumInvestAmount,
            "Investment amount must be equal more than minimum investment amount"
        );
        uint adminFee = (_investAmount * depositFeePercent) / 100;
        uint totalPayAmount = _investAmount + adminFee;
        require(
            _investAmountByFee >= totalPayAmount,
            "Your desired amount must also cover fee"
        );
        //giving refer reward
        uint referRewardAmount = (_investAmount * referRewardPercent) / 100;
        _giveReferReward(_refer, referRewardAmount);

        address refer;
        if (_refer != address(0) && _refer != owner()) {
            require(
                investInfo[_refer].totalInvestmentAmount > 0,
                "Refer does not investore"
            );
            refer = _refer;
        } else {
            refer = owner();
        }

        // give invest share amount to the owner
        uint ownerShareAmount = _investAmount * ownerInvestSharePercent/100;
        ownerInvestShareAmount += ownerShareAmount;
        if (investInfo[msg.sender].refer == address(0)) {
            // create info structure for msg.sender
            investInfo[msg.sender] = InvestInfo(
                refer, //refer
                _investAmount, //total investment amount
                (_investAmount * rewardPercent) / 100, //total reward amount
                (_investAmount * rewardPercent) / 100, //remained reward amount
                block.timestamp, //investment start time
                block.timestamp + endTimePeriod, //investment end time
                block.timestamp, // lastClaimedInvestRewardTime
                true // isActive
            );
            // investInfo[msg.sender] = userInvestInfo;
            allInviteRewards[msg.sender] = 0;
        } else if (
            investInfo[msg.sender].refer != address(0) &&
            (allInviteRewards[msg.sender] +
                getTotalInvestRewardsUntillNow(msg.sender) >=
                investInfo[msg.sender].totalInvestReward ||
                block.timestamp >= investInfo[msg.sender].investmentEndTime)
        ) {
            uint unrealizedInvestReward = getUnclaimedRewards(msg.sender);
            previousUnclaimedInvestReward[msg.sender] += unrealizedInvestReward;
            // create info structure for msg.sender
            investInfo[msg.sender] = InvestInfo(
                refer, //refer
                _investAmount, //total investment amount
                (_investAmount * rewardPercent) / 100, //total reward amount
                (_investAmount * rewardPercent) / 100, //remained reward amount
                block.timestamp, //investment start time
                block.timestamp + endTimePeriod, //investment end time
                block.timestamp, // lastClaimedInvestRewardTime
                true // isActive
            );
            // investInfo[msg.sender] = userInvestInfo;
            allInviteRewards[msg.sender] = 0;
        } else {
            // uint unrealizedInvestReward = getUnclaimedRewards(msg.sender);
            // uint claimedInvestRewards = getClaimedRewards(msg.sender);
            uint totalInvestRewardUntillNow = getTotalInvestRewardsUntillNow(msg.sender);
            previousUnclaimedInvestReward[msg.sender] += getUnclaimedRewards(msg.sender);
            // uint remainedInvestReward = investInfo[msg.sender].remainedInvestReward - unrealizedInvestReward;
            uint firstTotalInvestmentAmount = investInfo[msg.sender].totalInvestmentAmount;
            uint firstTotalInvestReward = investInfo[msg.sender].totalInvestReward;
            
            // create info structure for msg.sender
            investInfo[msg.sender] = InvestInfo(
                refer, //refer
                _investAmount + firstTotalInvestmentAmount, //total investment amount
                ((_investAmount*rewardPercent)/100 + firstTotalInvestReward - totalInvestRewardUntillNow), //total reward amount
                ((_investAmount*rewardPercent)/100 + firstTotalInvestReward - totalInvestRewardUntillNow), //remained reward amount
                block.timestamp, //investment start time
                block.timestamp + endTimePeriod, //investment end time
                block.timestamp, // lastClaimedInvestRewardTime
                true // isActive
            );
            // investInfo[msg.sender] = userInvestInfo;
            // allInviteRewards[msg.sender] += unrealizedInvestReward;
        }
        //add user to user list
        _addUser(msg.sender);
        //transfer funds from user to the contract
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(investTokenAddress),
            msg.sender,
            address(this),
            _investAmount
        );
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(investTokenAddress),
            msg.sender,
            owner(),
            adminFee
        );

        //history
        historyInvestAmount += _investAmount;
        emit InvestEvent(_investAmount, msg.sender, block.timestamp);
    }

    function claimAllReward() public {
        require(
            freezed[msg.sender] == false,
            "You can not withdraw because you are freezed"
        );
        uint userInviteReward = inviteRewards[msg.sender];
        uint userPreviousReward = previousUnclaimedInvestReward[msg.sender];
        uint userUnclaimedReward = getUnclaimedRewards(msg.sender);
        uint userAllReward = userAllRewards(msg.sender);
        uint ownerFee = (userAllReward * withdrawFeePercent) / 100;
        uint userFinalReward = userAllReward - ownerFee;
        //
        if(userUnclaimedReward > 0){
        investInfo[msg.sender].remainedInvestReward -= userUnclaimedReward;
        investInfo[msg.sender].lastClaimedInvestRewardTime = block.timestamp;
        }
        userClaimedRewards[msg.sender] += userAllReward;
        allUsersInviteRewardAmount -= inviteRewards[msg.sender];
        inviteRewards[msg.sender] = 0;
        previousUnclaimedInvestReward[msg.sender] = 0;
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(investTokenAddress),
            msg.sender,
            userFinalReward
        );
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(investTokenAddress),
            owner(),
            ownerFee
        );
        //history
        historyClaimedAllRewards += userAllReward;
        historyClaimedInviteRewards += userInviteReward;
        historyClaimedInvestRewards += userUnclaimedReward + userPreviousReward;
        if(msg.sender == owner()){
            historyClaimedOwnerInviteRewards += userInviteReward;
        }
        emit WithdrawUserReward(userAllReward, msg.sender, block.timestamp);
    }


    function claimAllRewardOfUserByOwner(address _user) public onlyOwner {
        uint userUnclaimedReward = getUnclaimedRewards(_user);
        uint userAllReward = userAllRewards(_user);
        uint ownerFee = (userAllReward * withdrawFeePercent) / 100;
        uint userFinalReward = userAllReward - ownerFee;
        if(userUnclaimedReward > 0){
        investInfo[_user].remainedInvestReward -= userUnclaimedReward;
        investInfo[_user].lastClaimedInvestRewardTime = block.timestamp;
        }
        uint userInviteReward = inviteRewards[_user];
        uint userPreviousReward = previousUnclaimedInvestReward[_user];
        userClaimedRewards[_user] += userAllReward;
        allUsersInviteRewardAmount -= inviteRewards[_user];
        inviteRewards[_user] = 0;
        previousUnclaimedInvestReward[_user] = 0;
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(investTokenAddress),
            owner(),
            userFinalReward
        );
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(investTokenAddress),
            owner(),
            ownerFee
        );
        
        //history
        historyClaimedAllRewards += userAllReward;
        historyClaimedInviteRewards += userInviteReward;
        historyClaimedInvestRewards += userUnclaimedReward + userPreviousReward;
        emit WithdrawUserReward(userAllReward, _user, block.timestamp);
    }


    function withdrawInsuranceRewardAmountByOwner(uint _amount) public onlyOwner {
        uint insuranceRewardAmount;
        if(IERC20Upgradeable(investTokenAddress).balanceOf(address(this)) > ownerInvestShareAmount + allUsersInviteRewardAmount){
            insuranceRewardAmount = IERC20Upgradeable(investTokenAddress).balanceOf(address(this)) - ownerInvestShareAmount - allUsersInviteRewardAmount;
        }
        require(insuranceRewardAmount > 0, "Contract doesnt have balance more than owner share and invite rewards");
        require(insuranceRewardAmount >= _amount, "Contract balance is less than the amount that you want to withdraw");
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(investTokenAddress),
            msg.sender,
            _amount
        );

        //history
        historyWithdrawFreeBalance += _amount;
        emit WithdrawFreeBalance(_amount, msg.sender, block.timestamp);
    }


    function withdrawContractBalance(uint _amount) public onlyOwner {
        require(IERC20Upgradeable(investTokenAddress).balanceOf(address(this)) >= _amount, "Contract balance is less than the amount that you want to withdraw");
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(investTokenAddress),
            msg.sender,
            _amount
        );

        //history
        historyWithdrawEmergency += _amount;
        emit WithdrawEmergency(_amount, msg.sender, block.timestamp);
    }


    function depositToken(uint _amount) public onlyOwner {
        
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(investTokenAddress),
            msg.sender,
            address(this),
            _amount
        );

        //history
        historyDepositByOwner += _amount;
        emit DepositByOwner(_amount, msg.sender, block.timestamp);
    }

    
}
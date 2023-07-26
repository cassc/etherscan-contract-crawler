// SPDX-License-Identifier: MIT
// Author: Sobi (Ciphers)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol"; //library
import "./AURAStakingInterfaces.sol";

error InsufficientBalance();
error InsufficientRewardsInPool();
error ActiveUser(uint256);
error TimeIncorrect();
error ContractAddressInvalid();
error AlreadyStaked();
error StakeYourAmount();
error InsufficientStakes();
error AlreadyUnstaked();
error NotExpiredYet();
error UnStakeFirst();
error InvalidUser();

contract AURAStaking is
    Ownable,
    Pausable,
    ReentrancyGuard,
    UserStats,
    Reward,
    Staking
{
    using Address for address;

    struct userStats {
        uint256 expiry; //the time of stake (update once withdrawal or stake)
        uint256 since; //The time on which the stakes are gettitng expired
        uint256 currentlyStaked; //Pending Withdrawal (update when stake & withdrawal)
        uint256 totalWithdrawal; //Total Withdraw of staked amount (update when withdrawal)
        uint256 totalPendingReward; //Pending Claim reward
        uint256 totalAccumulatedReward; //Withdrawn claim reward  (update when claimed)
        uint256 lockingPeriod; //Time in Seconds of the locking time
        bool unstake; //once the users has unstaked they can withdraw after 7 days it's all amount
    }

    IERC20 public token;
    uint256 APR;
    uint256 minStakingAmount;
    uint256 allocatedReward;
    uint256 totalStakedInPool;
    uint256 totalDelegates;
    mapping(address => userStats) user;

    constructor(
        IERC20 _token,
        uint256 _APR,
        uint256 _MinStakingAmount
    ) {
        require(address(_token) != address(0), "The address is not correct");
        token = _token;
        APR = _APR;
        minStakingAmount = _MinStakingAmount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function CurrentAPR() public view override returns (uint256) {
        return APR;
    }

    function ChangeAPR(uint256 _APR) public override onlyOwner returns (bool) {
        APR = _APR;
        return true;
    }

    function ChangeMinStakingAmount(uint256 _MinAmount)
        public
        override
        onlyOwner
        returns (bool)
    {
        minStakingAmount = _MinAmount;
        return true;
    }

    function MinStakingAmount() public view override returns (uint256) {
        return minStakingAmount;
    }

    //The total rewards remaining in the pool. These rewards are reserved for the new users that are going to stake into the pool.
    function AllocationOfRewards() public view override returns (uint256) {
        return allocatedReward;
    }

    function IncreaseAllocationReward(uint256 _amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        allocatedReward += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        return true;
    }

    function DecreaseAllocationReward(uint256 _amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        allocatedReward -= _amount;
        token.transfer(msg.sender, _amount);
        return true;
    }

    function TransferAllocatedRewardFromContractToOwner(uint256 _amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        token.transfer(msg.sender, _amount);
        return true;
    }

    //If someone sends Ethers mistakenly
    function withdrawEther() public onlyOwner nonReentrant returns (bool) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        return success;
    }

    function checkContractValidity() public view returns (bool) {
        return address(this).isContract();
    }

    //Re-Fund scenario
    function EmergencyWithdrawal(address _user, uint256 _amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        token.transfer(_user, _amount);
        return true;
    }

    function TotalWithdrawal(address _user)
        public
        view
        override
        returns (uint256)
    {
        return user[_user].totalWithdrawal;
    }

    function TotalPendingReward(address _user)
        public
        view
        override
        returns (uint256)
    {
        return user[_user].totalPendingReward;
    }

    function TotalAccumulatedReward(address _user)
        public
        view
        override
        returns (uint256)
    {
        return user[_user].totalAccumulatedReward;
    }

    function CalculateReward(uint256 _amount, uint256 _time)
        public
        view
        override
        returns (uint256)
    {
        return ((_time * _amount * APR) / 365 days) / 100;
    }

    //Number of users staked in the Staking Pool
    function TotalDelegates() public view override returns (uint256) {
        return totalDelegates;
    }

    //The user's Current status of the stakes
    function CurrentlyStaked(address _user)
        public
        view
        override
        returns (uint256)
    {
        return user[_user].currentlyStaked;
    }

    //The user's current status of the stakes is whether active?
    function HasStake(address _user) public view override returns (bool) {
        if (user[_user].currentlyStaked == 0) {
            return false;
        }
        return true;
    }

    function userSTATS(address _user) public view onlyOwner() returns(userStats memory){
       return user[_user];
    }


    //Total stakes in the pool status
    function TotalStakedInPool() public view override returns (uint256) {
        return totalStakedInPool;
    }

    //pause it when finished
    function Stake(uint256 amount, uint256 time)
        public
        override
        whenNotPaused
        returns (bool)
    {
        uint256 RewardOFUser = CalculateReward(amount, time);
        if (
            token.balanceOf(_msgSender()) < (amount) ||
            amount < minStakingAmount
        ) revert InsufficientBalance();
        if (time < 1209600 || time > 31536000) revert TimeIncorrect();
        if (user[_msgSender()].currentlyStaked == 0) {
            unchecked {
                ++totalDelegates;
            }
        }
        if (AllocationOfRewards() < RewardOFUser)
            revert InsufficientRewardsInPool();

        if (user[_msgSender()].since > 0) revert AlreadyStaked();
        _stake(amount, time, RewardOFUser);
        totalStakedInPool += amount ;
        emit User_Staked(
            _msgSender(),
            amount,
            user[_msgSender()].lockingPeriod
        );
        return true;
    }

    function _stake(
        uint256 _amount,
        uint256 _time,
        uint256 _reward
    ) internal {
        user[_msgSender()].since = block.timestamp;
        user[_msgSender()].expiry = block.timestamp + _time;
        user[_msgSender()].currentlyStaked += _amount;
        user[_msgSender()].totalPendingReward += _reward;
        user[_msgSender()].lockingPeriod += _time;
        allocatedReward -= _reward;
        token.transferFrom(_msgSender(), address(this), _amount);
    }

    function ReStake(uint256 amount, uint256 time)
        public
        override
        whenNotPaused
        returns (bool)
    {
        uint256 RewardOFUser = 
            CalculateReward(
                (user[_msgSender()].currentlyStaked + amount ),
                time
            );
        if (
            token.balanceOf(_msgSender()) < ( amount) ||
            amount < minStakingAmount
        ) revert InsufficientBalance();
        if (time < 1209600 || time > 31536000) revert TimeIncorrect();
        if (user[_msgSender()].currentlyStaked == 0) {
            unchecked {
                ++totalDelegates;
            }
        }
        if (AllocationOfRewards() < RewardOFUser)
            revert InsufficientRewardsInPool();

        if (user[_msgSender()].since == 0) revert StakeYourAmount();
        _reStake(amount, time, RewardOFUser);
        totalStakedInPool += amount ;
        emit User_ReStaked(
            _msgSender(),
            amount,
            user[_msgSender()].lockingPeriod,
            user[_msgSender()].currentlyStaked
        );
        return true;
    }

    function _reStake(
        uint256 _amount,
        uint256 _time,
        uint256 _reward
    ) internal {
        user[_msgSender()].expiry = (_time + user[_msgSender()].expiry);
        user[_msgSender()].currentlyStaked += _amount;
        user[_msgSender()].totalPendingReward += _reward;
        user[_msgSender()].unstake = false;
        user[_msgSender()].lockingPeriod += _time;
        allocatedReward -= _reward;
        token.transferFrom(_msgSender(), address(this), _amount);
    }

    //A user can withdraw after 7 days of unstaking it's amount.
    function UnStake() public override whenNotPaused returns (bool) {
        if (user[_msgSender()].unstake == true) revert AlreadyUnstaked();
        if (user[_msgSender()].currentlyStaked == 0)
            revert InsufficientStakes();
        if (user[_msgSender()].expiry > block.timestamp) revert NotExpiredYet();
        _unStake();
        emit User_Unstake(
            _msgSender(),
            user[_msgSender()].currentlyStaked,
            user[_msgSender()].expiry
        );
        return true;
    }

    function _unStake() internal {
        user[_msgSender()].expiry += 604800; //7 days
        user[_msgSender()].unstake = true;
        totalDelegates--;
    }

    function Withdraw() public override whenNotPaused returns (bool) {
        if (user[_msgSender()].unstake == false) revert UnStakeFirst();
        if (user[_msgSender()].expiry > block.timestamp) revert NotExpiredYet();
        if (user[_msgSender()].currentlyStaked <= 0) revert NotExpiredYet();
        _withdraw();
        emit User_Withdraw(_msgSender(), user[_msgSender()].totalWithdrawal);
        return true;
    }

    function _withdraw() internal {
        user[_msgSender()].totalWithdrawal = user[_msgSender()].currentlyStaked;
        token.transfer(msg.sender, user[_msgSender()].currentlyStaked);
        user[_msgSender()].since = 0;
        user[_msgSender()].currentlyStaked = 0;
        if (
            user[_msgSender()].totalPendingReward == 0 &&
            user[_msgSender()].currentlyStaked == 0
        ) {
            delete user[_msgSender()];
        }
    }

    function Claim() public override returns (bool) {
        if (user[_msgSender()].totalPendingReward == 0) revert InvalidUser();
        _claim();
        return true;
    }

    function _claim() internal {
        uint256 rewardPerSecond = (user[_msgSender()].totalPendingReward /
            user[_msgSender()].lockingPeriod);
        uint256 rewardTillToday = block.timestamp - user[_msgSender()].since;
        uint256 claim = rewardPerSecond * rewardTillToday;

        if (block.timestamp >= user[_msgSender()].expiry) {
            token.transfer(msg.sender, user[_msgSender()].totalPendingReward);
            emit User_Claim(
                _msgSender(),
                user[_msgSender()].totalPendingReward,
                0
            );
            user[_msgSender()].totalAccumulatedReward += user[_msgSender()]
                .totalPendingReward;
            user[_msgSender()].totalPendingReward = 0;
        } else {
            token.transfer(msg.sender, claim);
            user[_msgSender()].totalAccumulatedReward += claim;
            user[_msgSender()].totalPendingReward -= claim;
            emit User_Claim(
                _msgSender(),
                claim,
                user[_msgSender()].totalPendingReward
            );
        }

        if (
            user[_msgSender()].totalPendingReward == 0 &&
            user[_msgSender()].currentlyStaked == 0
        ) {
            delete user[_msgSender()];
        }
    }
}
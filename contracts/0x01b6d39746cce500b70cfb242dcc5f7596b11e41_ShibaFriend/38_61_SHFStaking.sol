// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Staking Contract
*/
contract SHFStaking is AccessControlUpgradeable, PausableUpgradeable{
    //Using safemath
    using SafeMath for uint256;

    address public tokenAddress;

    enum StakePlanStatus{ WITHDREW, IN_PROGRESS }
    enum PlanStatus{ INACTIVE, ACTIVE }
    //Stakes Mapping
    /*
        userStakes[address] => array
    */
    mapping(address => StakePlan[]) public userStakes;
    ContractPlan[] public contractPlans;

    struct StakePlan {
        uint256 amount;
        uint256 planId;
        StakePlanStatus status;
        uint256 stakeTime;
        uint256 dueTime;
    }

    struct ContractPlan {
        uint256 period; // minutes
        PlanStatus status;
        uint256 rate;
        uint256 minimumAmount; // Minimum of token to be staked
        uint256 maximumAmount; // Maximum amount of token to be staked
        uint256 stakedAmount; // Amount of staked tokens
    }

    // Contract's Events
    event Stake(address indexed sender, uint256 amount , uint256 planId);
    // Contract's Events
    event WithDraw(address indexed sender, uint256 amount , uint256 stakeId);

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();

    }

    /*
        admin's functions
    */
    function setTokenAddress(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _currency;
    }

    function addPlan(uint256 period, uint256 rate , uint256 minimumAmount , uint256 maximumAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokenAddress != address(0), "SHFStaking: Token must be specified");
        require(period > 0 , "SHFStaking: Plan period should be positive");
        require(rate > 0 , "SHFStaking: Plan interest should be positive");
        require(minimumAmount >= 0 , "SHFStaking: Plan minimum should be positive");
        require(maximumAmount >= minimumAmount , "SHFStaking: Plan minimum should smaller than maximum");

        uint256 maximumWithInterest = maximumAmount.mul(rate).div(100);

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), maximumWithInterest);
        contractPlans.push(ContractPlan(period, PlanStatus.ACTIVE, rate , minimumAmount, maximumAmount, 0));
    }

    function deactivePlan(uint256 planId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(contractPlans[planId].status == PlanStatus.ACTIVE, "SHFStaking: Plan not found");
        contractPlans[planId].status = PlanStatus.INACTIVE;
    }

    function activePlan(uint256 planId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(contractPlans[planId].status == PlanStatus.INACTIVE, "SHFStaking: Plan not found");
        contractPlans[planId].status = PlanStatus.ACTIVE;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        User's functions
    */
    /**
    * @notice Stake method that update the user's balance
    */
    function stake(uint256 planId, uint256 tokenAmount)
        external
    {

        require(contractPlans[planId].status == PlanStatus.ACTIVE, "SHFStaking: This plan is not acceptable");
        require(contractPlans[planId].minimumAmount <= tokenAmount, "SHFStaking: This plan is not acceptable");
        require(contractPlans[planId].maximumAmount >= contractPlans[planId].stakedAmount.add(tokenAmount), "SHFStaking: Staking amount reached limit");

        // get tokens from sender
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        contractPlans[planId].stakedAmount = contractPlans[planId].stakedAmount.add(tokenAmount);

        // Generate new stake plan with id is the index in
        uint256 stakeTime;
        uint256 dueTime;
        stakeTime = block.timestamp;
        dueTime = stakeTime.add(contractPlans[planId].period * 1 minutes);

        userStakes[msg.sender].push(StakePlan(tokenAmount, planId, StakePlanStatus.IN_PROGRESS , stakeTime, dueTime));

        // emit the event to notify the blockchain that we have correctly Staked some fund for the user
        emit Stake(msg.sender, tokenAmount , planId);
    }

    /**
    * @notice Allow users to withdraw their staked amount from the contract
    */
    function withdraw(uint256 stakeId)
        external
    {
        // check if the user has balance to withdraw
        require(userStakes[msg.sender][stakeId].amount > 0, "SHFStaking: You don't have balance to withdraw");
        require(userStakes[msg.sender][stakeId].status == StakePlanStatus.IN_PROGRESS , "SHFStaking: Cannot withdraw again");
        // Check stake plan can withdraw
        require(isWithdrawAble(stakeId) == true, "SHFStaking: Stake plan still in locktime");

        uint256 stakeAmount;
        uint256 withdrawAmount;
        uint256 interest;

        stakeAmount = userStakes[msg.sender][stakeId].amount;
        // Change stake status to withdrew
        userStakes[msg.sender][stakeId].status = StakePlanStatus.WITHDREW;

        // Calculate the interest
        interest = calculateInterest(stakeId);
        withdrawAmount = stakeAmount.add(interest);
        //Transfer balance back to the user
        require(IERC20(tokenAddress).transfer(msg.sender,withdrawAmount), "SHFStaking: Failed to send user balance back to the user");
        emit WithDraw(msg.sender, withdrawAmount , stakeId);
    }

    function calculateInterest(uint256 stakeId)
        public
        view
        returns(uint)
    {
        uint256 planId;
        planId = userStakes[msg.sender][stakeId].planId;
        return userStakes[msg.sender][stakeId].amount.mul(contractPlans[planId].rate).div(100);
    }

    function isWithdrawAble(uint256 stakeId)
        public
        view
        returns(bool)
    {
        if(userStakes[msg.sender][stakeId].dueTime <= block.timestamp){
            return true;
        }
        return false;
    }

    function totalPlan()
        public
        view
        returns(uint256)
    {
        return contractPlans.length;
    }

    function _userStake(address _user)
        internal
        view
        returns(StakePlan[] memory)
    {
        StakePlan[] memory ret = new StakePlan[](userStakes[_user].length);
        for (uint i = 0; i < userStakes[_user].length; i++) {
            ret[i] = userStakes[_user][i];
        }
        return ret;
    }

    function adminGetUserStake(address _user)
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(StakePlan[] memory)
    {
        return _userStake(_user);
    }

    function userStake()
        public
        view
        returns(StakePlan[] memory)
    {
        return _userStake(msg.sender);
    }

    function getAllPlans()
        public
        view
        returns (ContractPlan[] memory)
    {
        ContractPlan[] memory ret = new ContractPlan[](contractPlans.length);
        for (uint i = 0; i < contractPlans.length; i++) {
            ret[i] = contractPlans[i];
        }
        return ret;
    }
}
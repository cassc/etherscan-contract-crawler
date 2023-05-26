// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTYToken.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NFTYStakingUpgradeable is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    // state variables
    NFTYToken nftyToken;
    address private _NFTYTokenAddress;
    uint256 private _totalStakedToken;
    uint256[6] private _rewardRate;

    // creating a new role for admin
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // event for informing a new stake
    event NewStake(address indexed staker, uint256 amount);

    // event for informing the release of reward
    event RewardReleased(address indexed staker, uint256 reward);

    //event for informing the addition of amount to the existing stake
    event StakeUpgraded(
        address indexed staker,
        uint256 amount,
        uint256 totalStake
    );

    // event for informing when someone unstakes
    event StakeReleased(
        address indexed staker,
        uint256 amount,
        uint256 remainingStake
    );

    // event for informing the change of reward rate
    event RateChanged(
        address indexed admin,
        uint8 rank,
        uint256 oldRate,
        uint256 newRate
    );

    // event for informing the transfer of all tokens
    // to the nfty owner
    event TransferredAllTokens(address caller, uint256 amount);

    // modifier for checking the zero address
    modifier isRealAddress(address account) {
        require(account != address(0), "NFTYStaking: address is zero address");
        _;
    }

    // modifier for checking the real amount
    modifier isRealValue(uint256 value) {
        require(value > 0, "NFTYStaking: value must be greater than zero");
        _;
    }

    // modifier for checking if the sendeer is a staker
    modifier isStaker(address account) {
        require(
            StakersData[account].amount > 0,
            "NFTYStaking: caller is not a staker"
        );
        _;
    }

    // structure for storing the staker data
    struct StakeData {
        uint256 amount;
        uint256 reward;
        uint256 stakingTime;
        uint256 lastClaimTime;
    }

    // mapping for pointing to the stakers data
    mapping(address => StakeData) public StakersData;

    function initialize(address NFTYTokenAddress)
        public
        isRealAddress(NFTYTokenAddress)
        isRealAddress(_msgSender())
        initializer
    {
        __ReentrancyGuard_init();
        __AccessControl_init();
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _NFTYTokenAddress = NFTYTokenAddress;
        nftyToken = NFTYToken(NFTYTokenAddress);
        _rewardRate = [13579, 14579, 15079, 15579, 15829, 16079]; // 13.579%, 14.579%, 15.079%, 15.579%, 16.079%
    }

    function transferOwnership(address _newOwner)
        external
        onlyRole(ADMIN_ROLE)
    {
        nftyToken.transferOwnership(_newOwner);
    }

    // function for staking the token
    function stakeTokens(uint256 amount)
        external
        isRealAddress(_msgSender())
        isRealValue(amount)
        returns (bool)
    {
        require(amount >= _getAmount(1), "NFTYStaking: min stake amount is 1");
        require(
            nftyToken.balanceOf(_msgSender()) >= amount,
            "NFTYStaking: insufficient balance"
        );

        StakeData storage stakeData = StakersData[_msgSender()];

        uint256 _amount = stakeData.amount;

        // if already staking then add the amount to the existing stake
        if (_amount > 0) {
            // calculate the reward for the existing amount
            uint256 reward = _getReward(
                stakeData.stakingTime,
                stakeData.lastClaimTime,
                _amount
            );

            // update staker's data
            stakeData.reward += reward;
            stakeData.amount = _amount + amount;

            // emit the event for informing the upgraded stake
            emit StakeUpgraded(_msgSender(), amount, stakeData.amount);
        } else {
            // update staker's data
            stakeData.amount = amount;
            stakeData.stakingTime = block.timestamp;

            // emit the event for informing the new stake
            emit NewStake(_msgSender(), amount);
        }

        stakeData.lastClaimTime = block.timestamp;

        // update the pool
        _totalStakedToken += amount;

        // transfer the amount to the staking contract
        bool result = nftyToken.transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        return result;
    }

    // function for claiming reward
    function claimRewards()
        external
        isRealAddress(_msgSender())
        isStaker(_msgSender())
    {
        require(
            nftyToken.owner() == address(this),
            "Staking contract is not the owner."
        );

        StakeData storage stakeData = StakersData[_msgSender()];
        uint256 _amount = stakeData.amount;

        uint256 reward = _getReward(
            stakeData.stakingTime,
            stakeData.lastClaimTime,
            _amount
        );
        reward = stakeData.reward + reward;

        // update the staker data
        stakeData.reward = 0;
        stakeData.lastClaimTime = block.timestamp;

        // emit the event for informing the release of reward
        emit RewardReleased(_msgSender(), reward);

        // mint the reward back to the stakers account
        nftyToken.mint(_msgSender(), reward);
    }

    // function for showing the reward at any time
    function showReward(address account)
        external
        view
        isRealAddress(_msgSender())
        isRealAddress(account)
        isStaker(account)
        returns (uint256)
    {
        StakeData storage stakeData = StakersData[account];
        uint256 _amount = stakeData.amount;

        uint256 reward = _getReward(
            stakeData.stakingTime,
            stakeData.lastClaimTime,
            _amount
        );
        reward = stakeData.reward + reward;

        return reward;
    }

    // function for unstaking all the tokens
    function unstakeAll() external {
        StakeData storage stakeData = StakersData[_msgSender()];
        uint256 amount = stakeData.amount;

        unstakeTokens(amount);
    }

    // function for changing the reward rate
    function changeRate(uint8 rank, uint256 rate)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(rate > 0 && rate <= 100000, "NFTYStaking: invalid rate");
        require(rank < 6, "NFTYStaking: invalid rank");

        uint256 oldRate = _rewardRate[rank];
        _rewardRate[rank] = rate;

        // emit the event for informing the change of rate
        emit RateChanged(_msgSender(), rank, oldRate, rate);
    }

    // function for returning the current reward rate
    function getRewardRates() external view returns (uint256[6] memory) {
        return _rewardRate;
    }

    // function for returning total stake token (pool)
    function getPool() external view returns (uint256) {
        return _totalStakedToken;
    }

    function getRewardRate(uint256 amount, uint256 stakingTime)
        public
        view
        returns (uint256 rewardRate)
    {
        uint256 rewardRate1;
        uint256 rewardRate2;
        stakingTime = block.timestamp - stakingTime;

        // reward rate based on the staking amount
        if (amount >= _getAmount(1) && amount < _getAmount(500)) {
            rewardRate1 = _rewardRate[0];
        } else if (amount >= _getAmount(500) && amount < _getAmount(10000)) {
            rewardRate1 = _rewardRate[1];
        } else if (amount >= _getAmount(10000) && amount < _getAmount(25000)) {
            rewardRate1 = _rewardRate[2];
        } else if (amount >= _getAmount(25000) && amount < _getAmount(50000)) {
            rewardRate1 = _rewardRate[3];
        } else if (amount >= _getAmount(50000) && amount < _getAmount(100000)) {
            rewardRate1 = _rewardRate[4];
        } else {
            rewardRate1 = _rewardRate[5];
        }

        // reward rate based on staking time
        if (stakingTime < 30 days) {
            rewardRate2 = _rewardRate[0];
        } else if (stakingTime >= 30 days && stakingTime < 45 days) {
            rewardRate2 = _rewardRate[1];
        } else if (stakingTime >= 45 days && stakingTime < 90 days) {
            rewardRate2 = _rewardRate[2];
        } else if (stakingTime >= 90 days && stakingTime < 180 days) {
            rewardRate2 = _rewardRate[3];
        } else if (stakingTime >= 180 days && stakingTime < 365 days) {
            rewardRate2 = _rewardRate[4];
        } else {
            rewardRate2 = _rewardRate[5];
        }

        // find exact reward rate
        rewardRate = rewardRate1 < rewardRate2 ? rewardRate1 : rewardRate2;
    }

    // function for unstaking the specified amount
    function unstakeTokens(uint256 amount)
        public
        isRealAddress(_msgSender())
        isRealValue(amount)
        isStaker(_msgSender())
    {
        require(
            nftyToken.owner() == address(this),
            "Staking contract is not the owner."
        );

        StakeData storage stakeData = StakersData[_msgSender()];
        uint256 _amount = stakeData.amount;

        // check if the user has enough amount to unstake
        require(_amount >= amount, "NFTYStaking: not enough staked token");

        uint256 reward = _getReward(
            stakeData.stakingTime,
            stakeData.lastClaimTime,
            _amount
        );

        // if the staker is unstaking the whole amount
        if (stakeData.amount == amount) {
            uint256 totReward = reward + stakeData.reward;

            // update the staker data
            stakeData.reward = 0;
            stakeData.stakingTime = 0;

            // emit the event for informing the release of reward
            emit RewardReleased(_msgSender(), totReward);

            // mint reward to the user
            nftyToken.mint(_msgSender(), totReward);
        } else {
            // update the staker data
            stakeData.reward += reward;
        }

        stakeData.amount -= amount;
        stakeData.lastClaimTime = block.timestamp;

        _totalStakedToken -= amount;

        // emit the event for informing the unstake of tokens
        emit StakeReleased(_msgSender(), amount, stakeData.amount);

        nftyToken.transfer(_msgSender(), amount);
    }

    // function for finding the reward based on compound equation
    function _getReward(
        uint256 stakingTime,
        uint256 lastClaimTime,
        uint256 amount
    ) internal view returns (uint256 reward) {
        uint256 rewardRate = getRewardRate(amount, stakingTime);
        uint256 rewardTime = block.timestamp - lastClaimTime;
        uint256 rateForSecond = (rewardRate * 10**18) / 365 days;

        reward = (amount * rateForSecond * rewardTime) / 10**23;

        return reward;
    }

    // function for retrieving the exact amount
    function _getAmount(uint256 value) internal view returns (uint256) {
        return value * 10**uint256(nftyToken.decimals());
    }
}
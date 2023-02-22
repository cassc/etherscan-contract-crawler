// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./dependencies/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./dependencies/@openzeppelin/contracts/utils/math/Math.sol";
import "./dependencies/@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./access/Governable.sol";
import "./storage/RewardsStorage.sol";

/**
 * @title Rewards contract
 */
contract Rewards is ReentrancyGuard, Governable, RewardsStorageV1 {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    string public constant VERSION = "1.0.0";
    uint256 public constant REWARD_DURATION = 30 days;

    /// Emitted after reward added
    event RewardAdded(address indexed rewardToken, uint256 reward, uint256 rewardDuration);

    /// Emitted whenever any user claim rewards
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);

    /// Emitted after adding new rewards token into rewardTokens array
    event RewardTokenAdded(address indexed rewardToken, address[] existingRewardTokens);

    /// Emitted when distributor approval is updated
    event RewardDistributorApprovalUpdated(address rewardsToken, address distributor, bool approved);

    function initialize(IESMET esMET_) external initializer {
        require(address(esMET_) != address(0), "esMET-is-null");

        __Governable_init();

        esMET = esMET_;
    }

    /**
     * @notice Get claimable rewards
     * @param account_ The account
     * @return _rewardTokens The addresses of the reward tokens
     * @return _claimableAmounts The claimable amounts
     */
    function claimableRewards(
        address account_
    ) external view override returns (address[] memory _rewardTokens, uint256[] memory _claimableAmounts) {
        uint256 _len = rewardTokens.length;

        _rewardTokens = new address[](_len);
        _claimableAmounts = new uint256[](_len);

        uint256 _totalSupply;
        uint256 _userBalance;
        for (uint256 i; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            (_totalSupply, _userBalance) = _getSupplyAndBalance(_rewardToken, account_);
            _rewardTokens[i] = _rewardToken;
            _claimableAmounts[i] = _claimable(_rewardToken, account_, _totalSupply, _userBalance);
        }
    }

    /**
     * @notice Claim earned rewards
     * @dev This function will claim rewards for all tokens being rewarded
     * @param account_ The account
     */
    function claimRewards(address account_) external override nonReentrant {
        uint256 _len = rewardTokens.length;

        uint256 _totalSupply;
        uint256 _userBalance;
        for (uint256 i; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            (_totalSupply, _userBalance) = _getSupplyAndBalance(_rewardToken, account_);

            _updateReward(_rewardToken, account_, _totalSupply, _userBalance);

            uint256 _rewardAmount = rewardOf[_rewardToken][account_].claimableRewardsStored;
            if (_rewardAmount > 0) {
                _claimReward(_rewardToken, account_, _rewardAmount);
            }
        }
    }

    /**
     * @notice Drip reward token and extend current reward duration by 30 days
     * User get drip based on their boosted MET amount
     * @dev Restricted method
     * @param rewardToken_ Reward token address
     * @param rewardAmount_  Reward amount
     */
    function dripRewardAmount(address rewardToken_, uint256 rewardAmount_) external override {
        require(rewards[rewardToken_].lastUpdateTime > 0, "reward-token-not-added");
        require(isRewardDistributor[rewardToken_][_msgSender()], "not-distributor");
        require(rewardAmount_ > 0, "incorrect-reward-amount");
        _dripRewardAmount(rewardToken_, rewardAmount_);
    }

    /**
     * @notice Returns timestamp of last reward update
     * @param _rewardToken The reward token
     * @return The timestamp
     */
    function lastTimeRewardApplicable(address _rewardToken) public view override returns (uint256) {
        return Math.min(block.timestamp, rewards[_rewardToken].periodFinish);
    }

    /**
     * @notice Update reward earning of user
     * @param account_ The account
     */
    function updateReward(address account_) external override {
        uint256 _len = rewardTokens.length;

        uint256 _totalSupply;
        uint256 _userBalance;
        for (uint256 i; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            (_totalSupply, _userBalance) = _getSupplyAndBalance(_rewardToken, account_);
            _updateReward(_rewardToken, account_, _totalSupply, _userBalance);
        }
    }

    /**
     * @notice Get claimable rewards for a reward token
     * @param rewardToken_ The address of the reward token
     * @param account_ The account
     * @param totalSupply_ The supply of reference (boosted or locked)
     * @param balance_ The balance of reference (boosted or locked)
     * @return The claimable amount
     */
    function _claimable(
        address rewardToken_,
        address account_,
        uint256 totalSupply_,
        uint256 balance_
    ) private view returns (uint256) {
        UserReward memory _userReward = rewardOf[rewardToken_][account_];
        uint256 _rewardPerTokenAvailable = _rewardPerToken(rewardToken_, totalSupply_) - _userReward.rewardPerTokenPaid;
        uint256 _rewardsEarnedSinceLastUpdate = (balance_ * _rewardPerTokenAvailable) / 1e18;
        return _userReward.claimableRewardsStored + _rewardsEarnedSinceLastUpdate;
    }

    /**
     * @notice Transfer claimable reward to user
     * @param rewardToken_ The reward token
     * @param account_ The account
     * @param reward_ The reward amount
     */
    function _claimReward(address rewardToken_, address account_, uint256 reward_) private {
        rewardOf[rewardToken_][account_].claimableRewardsStored = 0;
        IERC20(rewardToken_).safeTransfer(account_, reward_);
        emit RewardPaid(account_, rewardToken_, reward_);
    }

    /**
     * @notice Drip reward token and extend current reward duration by 30 days
     * User get drip based on their boosted MET amount
     * @param rewardToken_ Reward token address
     * @param rewardAmount_  Reward amount
     */
    function _dripRewardAmount(address rewardToken_, uint256 rewardAmount_) private {
        uint256 _balanceBefore = IERC20(rewardToken_).balanceOf(address(this));
        IERC20(rewardToken_).safeTransferFrom(_msgSender(), address(this), rewardAmount_);
        uint256 _dripAmount = IERC20(rewardToken_).balanceOf(address(this)) - _balanceBefore;

        Reward storage _reward = rewards[rewardToken_];
        uint256 _totalSupply = _reward.isBoosted ? esMET.totalBoosted() : esMET.totalLocked();
        _reward.rewardPerTokenStored = _rewardPerToken(rewardToken_, _totalSupply);

        if (block.timestamp >= _reward.periodFinish) {
            _reward.rewardPerSecond = _dripAmount / REWARD_DURATION;
        } else {
            uint256 _remainingPeriod = _reward.periodFinish - block.timestamp;
            uint256 _leftover = _remainingPeriod * _reward.rewardPerSecond;
            _reward.rewardPerSecond = (_dripAmount + _leftover) / REWARD_DURATION;
        }

        // Start new drip time
        _reward.lastUpdateTime = block.timestamp;
        _reward.periodFinish = block.timestamp + REWARD_DURATION;
        emit RewardAdded(rewardToken_, _dripAmount, REWARD_DURATION);
    }

    /**
     * @notice Get supply and balance for reference (i.e. locked or boosted)
     */
    function _getSupplyAndBalance(
        address rewardToken_,
        address account_
    ) private view returns (uint256 _totalSupply, uint256 _userBalance) {
        if (rewards[rewardToken_].isBoosted) {
            _totalSupply = esMET.totalBoosted();
            _userBalance = esMET.boosted(account_);
        } else {
            _totalSupply = esMET.totalLocked();
            _userBalance = esMET.locked(account_);
        }
    }

    /**
     * @notice Returns the reward per MET locked based on time elapsed since last notification multiplied by reward rate
     * @param rewardToken_ The reward token
     * @param totalSupply_ The supply of reference (boosted or locked)
     * @return The reward per MET
     */
    function _rewardPerToken(address rewardToken_, uint256 totalSupply_) private view returns (uint256) {
        if (totalSupply_ == 0) {
            return rewards[rewardToken_].rewardPerTokenStored;
        }

        uint256 _timeSinceLastUpdate = lastTimeRewardApplicable(rewardToken_) - rewards[rewardToken_].lastUpdateTime;
        uint256 _rewardsSinceLastUpdate = _timeSinceLastUpdate * rewards[rewardToken_].rewardPerSecond;
        uint256 _rewardsPerTokenSinceLastUpdate = (_rewardsSinceLastUpdate * 1e18) / totalSupply_;
        return rewards[rewardToken_].rewardPerTokenStored + _rewardsPerTokenSinceLastUpdate;
    }

    /**
     * @notice Update reward earning of user
     * @param rewardToken_ The address of the reward token
     * @param account_ The account
     * @param totalSupply_ The supply of reference (boosted or locked)
     * @param balance_ The balance of reference (boosted or locked)
     */
    function _updateReward(address rewardToken_, address account_, uint256 totalSupply_, uint256 balance_) private {
        uint256 _rewardPerTokenStored = _rewardPerToken(rewardToken_, totalSupply_);
        Reward storage _reward = rewards[rewardToken_];
        _reward.rewardPerTokenStored = _rewardPerTokenStored;
        _reward.lastUpdateTime = lastTimeRewardApplicable(rewardToken_);
        if (account_ != address(0)) {
            rewardOf[rewardToken_][account_] = UserReward({
                claimableRewardsStored: _claimable(rewardToken_, account_, totalSupply_, balance_).toUint128(),
                rewardPerTokenPaid: _rewardPerTokenStored.toUint128()
            });
        }
    }

    /** Governance methods **/

    /**
     * @notice Allow/disallow address as a reward distributor for a given token
     * @param rewardsToken_ The reward token
     * @param distributor_ The distributor address
     * @param approved_ The approved boolean flag
     */
    function setRewardDistributorApproval(
        address rewardsToken_,
        address distributor_,
        bool approved_
    ) external onlyGovernor {
        require(rewards[rewardsToken_].lastUpdateTime > 0, "reward-token-not-added");
        isRewardDistributor[rewardsToken_][distributor_] = approved_;
        emit RewardDistributorApprovalUpdated(rewardsToken_, distributor_, approved_);
    }

    /**
     * @notice add new reward token for distribution
     * @param rewardsToken_ Reward token address
     * @param distributor_  Authorized called to call dripRewardAmount
     * @param isBoosted_ If reward token is boosted than rewards is distributed on boost amount depends on lock period
     */
    function addRewardToken(address rewardsToken_, address distributor_, bool isBoosted_) external onlyGovernor {
        require(rewards[rewardsToken_].lastUpdateTime == 0, "reward-already-added");
        rewards[rewardsToken_] = Reward({
            isBoosted: isBoosted_,
            periodFinish: block.timestamp,
            rewardPerSecond: 0,
            rewardPerTokenStored: 0,
            lastUpdateTime: block.timestamp
        });
        emit RewardTokenAdded(rewardsToken_, rewardTokens);
        rewardTokens.push(rewardsToken_);
        isRewardDistributor[rewardsToken_][distributor_] = true;
    }
}
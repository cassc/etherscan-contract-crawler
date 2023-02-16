// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../dependencies/openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/vesper/IPoolRewards.sol";
import "../interfaces/vesper/IVesperPool.sol";

contract PoolRewardsStorage {
    /// Vesper pool address
    address public pool;

    /// Array of reward token addresses
    address[] public rewardTokens;

    /// Reward token to valid/invalid flag mapping
    mapping(address => bool) public isRewardToken;

    /// Reward token to period ending of current reward
    mapping(address => uint256) public periodFinish;

    /// Reward token to current reward rate mapping
    mapping(address => uint256) public rewardRates;

    /// Reward token to Duration of current reward distribution
    mapping(address => uint256) public rewardDuration;

    /// Reward token to Last reward drip update time stamp mapping
    mapping(address => uint256) public lastUpdateTime;

    /// Reward token to Reward per token mapping. Calculated and stored at last drip update
    mapping(address => uint256) public rewardPerTokenStored;

    /// Reward token => User => Reward per token stored at last reward update
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;

    /// RewardToken => User => Rewards earned till last reward update
    mapping(address => mapping(address => uint256)) public rewards;
}

/// @title Distribute rewards based on vesper pool balance and supply
contract PoolRewards is Initializable, IPoolRewards, ReentrancyGuard, PoolRewardsStorage {
    string public constant VERSION = "5.1.0";
    using SafeERC20 for IERC20;

    /**
     * @dev Called by proxy to initialize this contract
     * @param pool_ Vesper pool address
     * @param rewardTokens_ Array of reward token addresses
     */
    function initialize(address pool_, address[] memory rewardTokens_) public initializer {
        require(pool_ != address(0), "pool-address-is-zero");
        uint256 _len = rewardTokens_.length;
        require(_len > 0, "invalid-reward-tokens");
        pool = pool_;
        rewardTokens = rewardTokens_;
        for (uint256 i; i < _len; i++) {
            isRewardToken[rewardTokens_[i]] = true;
        }
    }

    modifier onlyAuthorized() {
        require(msg.sender == IVesperPool(pool).governor(), "not-authorized");
        _;
    }

    /**
     * @notice Returns claimable reward amount.
     * @return _rewardTokens Array of tokens being rewarded
     * @return _claimableAmounts Array of claimable for token on same index in rewardTokens
     */
    function claimable(
        address account_
    ) external view virtual override returns (address[] memory _rewardTokens, uint256[] memory _claimableAmounts) {
        uint256 _totalSupply = IERC20(pool).totalSupply();
        uint256 _balance = IERC20(pool).balanceOf(account_);
        _rewardTokens = rewardTokens;
        uint256 _len = _rewardTokens.length;
        _claimableAmounts = new uint256[](_len);
        for (uint256 i; i < _len; i++) {
            _claimableAmounts[i] = _claimable(_rewardTokens[i], account_, _totalSupply, _balance);
        }
    }

    /**
     * @notice Claim earned rewards.
     * @dev This function will claim rewards for all tokens being rewarded
     */
    function claimReward(address account_) external virtual override nonReentrant {
        uint256 _totalSupply = IERC20(pool).totalSupply();
        uint256 _balance = IERC20(pool).balanceOf(account_);
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            _updateReward(_rewardToken, account_, _totalSupply, _balance);

            // Claim rewards
            uint256 _reward = rewards[_rewardToken][account_];
            if (_reward > 0 && _reward <= IERC20(_rewardToken).balanceOf(address(this))) {
                _claimReward(_rewardToken, account_, _reward);
                emit RewardPaid(account_, _rewardToken, _reward);
            }
        }
    }

    /// @notice Provides easy access to all rewardTokens
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    /// @notice Returns timestamp of last reward update
    function lastTimeRewardApplicable(address rewardToken_) public view override returns (uint256) {
        return block.timestamp < periodFinish[rewardToken_] ? block.timestamp : periodFinish[rewardToken_];
    }

    function rewardForDuration()
        external
        view
        override
        returns (address[] memory _rewardTokens, uint256[] memory _rewardForDuration)
    {
        _rewardTokens = rewardTokens;
        uint256 _len = _rewardTokens.length;
        _rewardForDuration = new uint256[](_len);
        for (uint256 i; i < _len; i++) {
            _rewardForDuration[i] = rewardRates[_rewardTokens[i]] * rewardDuration[_rewardTokens[i]];
        }
    }

    /**
     * @notice Rewards rate per pool token
     * @return _rewardTokens Array of tokens being rewarded
     * @return _rewardPerTokenRate Array of Rewards rate for token on same index in rewardTokens
     */
    function rewardPerToken()
        external
        view
        override
        returns (address[] memory _rewardTokens, uint256[] memory _rewardPerTokenRate)
    {
        uint256 _totalSupply = IERC20(pool).totalSupply();
        _rewardTokens = rewardTokens;
        uint256 _len = _rewardTokens.length;
        _rewardPerTokenRate = new uint256[](_len);
        for (uint256 i; i < _len; i++) {
            _rewardPerTokenRate[i] = _rewardPerToken(_rewardTokens[i], _totalSupply);
        }
    }

    /**
     * @notice Updated reward for given account.
     */
    function updateReward(address account_) external override {
        uint256 _totalSupply = IERC20(pool).totalSupply();
        uint256 _balance = IERC20(pool).balanceOf(account_);
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            _updateReward(rewardTokens[i], account_, _totalSupply, _balance);
        }
    }

    function _claimable(
        address rewardToken_,
        address account_,
        uint256 totalSupply_,
        uint256 balance_
    ) internal view returns (uint256) {
        uint256 _rewardPerTokenAvailable = _rewardPerToken(rewardToken_, totalSupply_) -
            userRewardPerTokenPaid[rewardToken_][account_];
        // claimable = rewards + rewards earned since last update
        return rewards[rewardToken_][account_] + ((balance_ * _rewardPerTokenAvailable) / 1e18);
    }

    function _claimReward(address rewardToken_, address account_, uint256 reward_) internal virtual {
        // Mark reward as claimed
        rewards[rewardToken_][account_] = 0;
        // Transfer reward
        IERC20(rewardToken_).safeTransfer(account_, reward_);
    }

    // There are scenarios when extending contract will override external methods and
    // end up calling internal function. Hence providing internal functions
    function _notifyRewardAmount(
        address[] memory rewardTokens_,
        uint256[] memory rewardAmounts_,
        uint256[] memory rewardDurations_,
        uint256 totalSupply_
    ) internal {
        uint256 _len = rewardTokens_.length;
        require(_len > 0, "invalid-reward-tokens");
        require(_len == rewardAmounts_.length && _len == rewardDurations_.length, "array-length-mismatch");
        for (uint256 i; i < _len; i++) {
            _notifyRewardAmount(rewardTokens_[i], rewardAmounts_[i], rewardDurations_[i], totalSupply_);
        }
    }

    function _notifyRewardAmount(
        address rewardToken_,
        uint256 rewardAmount_,
        uint256 rewardDuration_,
        uint256 totalSupply_
    ) internal {
        require(rewardToken_ != address(0), "incorrect-reward-token");
        require(rewardAmount_ > 0, "incorrect-reward-amount");
        require(rewardDuration_ > 0, "incorrect-reward-duration");
        require(isRewardToken[rewardToken_], "invalid-reward-token");

        // Update rewards earned so far
        rewardPerTokenStored[rewardToken_] = _rewardPerToken(rewardToken_, totalSupply_);
        if (block.timestamp >= periodFinish[rewardToken_]) {
            rewardRates[rewardToken_] = rewardAmount_ / rewardDuration_;
        } else {
            uint256 remainingPeriod = periodFinish[rewardToken_] - block.timestamp;

            uint256 leftover = remainingPeriod * rewardRates[rewardToken_];
            rewardRates[rewardToken_] = (rewardAmount_ + leftover) / rewardDuration_;
        }
        // Safety check
        require(
            rewardRates[rewardToken_] <= (IERC20(rewardToken_).balanceOf(address(this)) / rewardDuration_),
            "rewards-too-high"
        );
        // Start new drip time
        rewardDuration[rewardToken_] = rewardDuration_;
        lastUpdateTime[rewardToken_] = block.timestamp;
        periodFinish[rewardToken_] = block.timestamp + rewardDuration_;
        emit RewardAdded(rewardToken_, rewardAmount_, rewardDuration_);
    }

    function _rewardPerToken(address rewardToken_, uint256 totalSupply_) internal view returns (uint256) {
        if (totalSupply_ == 0) {
            return rewardPerTokenStored[rewardToken_];
        }

        uint256 _timeSinceLastUpdate = lastTimeRewardApplicable(rewardToken_) - lastUpdateTime[rewardToken_];
        // reward per token = rewardPerTokenStored + rewardPerToken since last update
        return
            rewardPerTokenStored[rewardToken_] +
            ((_timeSinceLastUpdate * rewardRates[rewardToken_] * 1e18) / totalSupply_);
    }

    function _updateReward(address rewardToken_, address account_, uint256 totalSupply_, uint256 balance_) internal {
        uint256 _rewardPerTokenStored = _rewardPerToken(rewardToken_, totalSupply_);
        rewardPerTokenStored[rewardToken_] = _rewardPerTokenStored;
        lastUpdateTime[rewardToken_] = lastTimeRewardApplicable(rewardToken_);
        if (account_ != address(0)) {
            rewards[rewardToken_][account_] = _claimable(rewardToken_, account_, totalSupply_, balance_);
            userRewardPerTokenPaid[rewardToken_][account_] = _rewardPerTokenStored;
        }
    }

    /************************************************************************************************
     *                                     Authorized function                                      *
     ***********************************************************************************************/

    /// @notice Add new reward token in existing rewardsToken array
    function addRewardToken(address newRewardToken_) external onlyAuthorized {
        require(newRewardToken_ != address(0), "reward-token-address-zero");
        require(!isRewardToken[newRewardToken_], "reward-token-already-exist");
        emit RewardTokenAdded(newRewardToken_, rewardTokens);
        rewardTokens.push(newRewardToken_);
        isRewardToken[newRewardToken_] = true;
    }

    /**
     * @notice Notify that reward is added. Only authorized caller can call
     * @dev Also updates reward rate and reward earning period.
     * @param rewardTokens_ Tokens being rewarded
     * @param rewardAmounts_ Rewards amount for token on same index in rewardTokens array
     * @param rewardDurations_ Duration for which reward will be distributed
     */
    function notifyRewardAmount(
        address[] memory rewardTokens_,
        uint256[] memory rewardAmounts_,
        uint256[] memory rewardDurations_
    ) external virtual override onlyAuthorized {
        _notifyRewardAmount(rewardTokens_, rewardAmounts_, rewardDurations_, IERC20(pool).totalSupply());
    }

    function notifyRewardAmount(
        address rewardToken_,
        uint256 rewardAmount_,
        uint256 rewardDuration_
    ) external virtual override onlyAuthorized {
        _notifyRewardAmount(rewardToken_, rewardAmount_, rewardDuration_, IERC20(pool).totalSupply());
    }
}
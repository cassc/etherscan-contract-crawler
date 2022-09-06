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
    string public constant VERSION = "4.0.0";
    using SafeERC20 for IERC20;

    /**
     * @dev Called by proxy to initialize this contract
     * @param _pool Vesper pool address
     * @param _rewardTokens Array of reward token addresses
     */
    function initialize(address _pool, address[] memory _rewardTokens) public initializer {
        require(_pool != address(0), "pool-address-is-zero");
        require(_rewardTokens.length != 0, "invalid-reward-tokens");
        pool = _pool;
        rewardTokens = _rewardTokens;
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            isRewardToken[_rewardTokens[i]] = true;
        }
    }

    modifier onlyAuthorized() {
        require(msg.sender == IVesperPool(pool).governor(), "not-authorized");
        _;
    }

    /**
     * @notice Notify that reward is added. Only authorized caller can call
     * @dev Also updates reward rate and reward earning period.
     * @param _rewardTokens Tokens being rewarded
     * @param _rewardAmounts Rewards amount for token on same index in rewardTokens array
     * @param _rewardDurations Duration for which reward will be distributed
     */
    function notifyRewardAmount(
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts,
        uint256[] memory _rewardDurations
    ) external virtual override onlyAuthorized {
        _notifyRewardAmount(_rewardTokens, _rewardAmounts, _rewardDurations, IERC20(pool).totalSupply());
    }

    function notifyRewardAmount(
        address _rewardToken,
        uint256 _rewardAmount,
        uint256 _rewardDuration
    ) external virtual override onlyAuthorized {
        _notifyRewardAmount(_rewardToken, _rewardAmount, _rewardDuration, IERC20(pool).totalSupply());
    }

    /// @notice Add new reward token in existing rewardsToken array
    function addRewardToken(address _newRewardToken) external onlyAuthorized {
        require(_newRewardToken != address(0), "reward-token-address-zero");
        require(!isRewardToken[_newRewardToken], "reward-token-already-exist");
        emit RewardTokenAdded(_newRewardToken, rewardTokens);
        rewardTokens.push(_newRewardToken);
        isRewardToken[_newRewardToken] = true;
    }

    /**
     * @notice Claim earned rewards.
     * @dev This function will claim rewards for all tokens being rewarded
     */
    function claimReward(address _account) external virtual override nonReentrant {
        uint256 _totalSupply = IERC20(pool).totalSupply();
        uint256 _balance = IERC20(pool).balanceOf(_account);
        uint256 _len = rewardTokens.length;
        for (uint256 i = 0; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            _updateReward(_rewardToken, _account, _totalSupply, _balance);

            // Claim rewards
            uint256 _reward = rewards[_rewardToken][_account];
            if (_reward != 0 && _reward <= IERC20(_rewardToken).balanceOf(address(this))) {
                _claimReward(_rewardToken, _account, _reward);
                emit RewardPaid(_account, _rewardToken, _reward);
            }
        }
    }

    /**
     * @notice Updated reward for given account.
     */
    function updateReward(address _account) external override {
        uint256 _totalSupply = IERC20(pool).totalSupply();
        uint256 _balance = IERC20(pool).balanceOf(_account);
        uint256 _len = rewardTokens.length;
        for (uint256 i = 0; i < _len; i++) {
            _updateReward(rewardTokens[i], _account, _totalSupply, _balance);
        }
    }

    /**
     * @notice Returns claimable reward amount.
     * @return _rewardTokens Array of tokens being rewarded
     * @return _claimableAmounts Array of claimable for token on same index in rewardTokens
     */
    function claimable(address _account)
        external
        view
        virtual
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimableAmounts)
    {
        uint256 _totalSupply = IERC20(pool).totalSupply();
        uint256 _balance = IERC20(pool).balanceOf(_account);
        uint256 _len = rewardTokens.length;
        _claimableAmounts = new uint256[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _claimableAmounts[i] = _claimable(rewardTokens[i], _account, _totalSupply, _balance);
        }
        _rewardTokens = rewardTokens;
    }

    /// @notice Provides easy access to all rewardTokens
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    /// @notice Returns timestamp of last reward update
    function lastTimeRewardApplicable(address _rewardToken) public view override returns (uint256) {
        return block.timestamp < periodFinish[_rewardToken] ? block.timestamp : periodFinish[_rewardToken];
    }

    function rewardForDuration()
        external
        view
        override
        returns (address[] memory _rewardTokens, uint256[] memory _rewardForDuration)
    {
        uint256 _len = rewardTokens.length;
        _rewardForDuration = new uint256[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _rewardForDuration[i] = rewardRates[rewardTokens[i]] * rewardDuration[rewardTokens[i]];
        }
        _rewardTokens = rewardTokens;
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
        uint256 _len = rewardTokens.length;
        _rewardPerTokenRate = new uint256[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _rewardPerTokenRate[i] = _rewardPerToken(rewardTokens[i], _totalSupply);
        }
        _rewardTokens = rewardTokens;
    }

    function _claimable(
        address _rewardToken,
        address _account,
        uint256 _totalSupply,
        uint256 _balance
    ) internal view returns (uint256) {
        uint256 _rewardPerTokenAvailable =
            _rewardPerToken(_rewardToken, _totalSupply) - userRewardPerTokenPaid[_rewardToken][_account];
        uint256 _rewardsEarnedSinceLastUpdate = (_balance * _rewardPerTokenAvailable) / 1e18;
        return rewards[_rewardToken][_account] + _rewardsEarnedSinceLastUpdate;
    }

    function _claimReward(
        address _rewardToken,
        address _account,
        uint256 _reward
    ) internal virtual {
        // Mark reward as claimed
        rewards[_rewardToken][_account] = 0;
        // Transfer reward
        IERC20(_rewardToken).safeTransfer(_account, _reward);
    }

    // There are scenarios when extending contract will override external methods and
    // end up calling internal function. Hence providing internal functions
    function _notifyRewardAmount(
        address[] memory _rewardTokens,
        uint256[] memory _rewardAmounts,
        uint256[] memory _rewardDurations,
        uint256 _totalSupply
    ) internal {
        uint256 _len = _rewardTokens.length;
        uint256 _amountsLen = _rewardAmounts.length;
        uint256 _durationsLen = _rewardDurations.length;
        require(_len != 0, "invalid-reward-tokens");
        require(_amountsLen != 0, "invalid-reward-amounts");
        require(_durationsLen != 0, "invalid-reward-durations");
        require(_len == _amountsLen && _len == _durationsLen, "array-length-mismatch");
        for (uint256 i = 0; i < _len; i++) {
            _notifyRewardAmount(_rewardTokens[i], _rewardAmounts[i], _rewardDurations[i], _totalSupply);
        }
    }

    function _notifyRewardAmount(
        address _rewardToken,
        uint256 _rewardAmount,
        uint256 _rewardDuration,
        uint256 _totalSupply
    ) internal {
        require(_rewardToken != address(0), "incorrect-reward-token");
        require(_rewardAmount != 0, "incorrect-reward-amount");
        require(_rewardDuration != 0, "incorrect-reward-duration");
        require(isRewardToken[_rewardToken], "invalid-reward-token");

        // Update rewards earned so far
        rewardPerTokenStored[_rewardToken] = _rewardPerToken(_rewardToken, _totalSupply);
        if (block.timestamp >= periodFinish[_rewardToken]) {
            rewardRates[_rewardToken] = _rewardAmount / _rewardDuration;
        } else {
            uint256 remainingPeriod = periodFinish[_rewardToken] - block.timestamp;

            uint256 leftover = remainingPeriod * rewardRates[_rewardToken];
            rewardRates[_rewardToken] = (_rewardAmount + leftover) / _rewardDuration;
        }
        // Safety check
        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        require(rewardRates[_rewardToken] <= (balance / _rewardDuration), "rewards-too-high");
        // Start new drip time
        rewardDuration[_rewardToken] = _rewardDuration;
        lastUpdateTime[_rewardToken] = block.timestamp;
        periodFinish[_rewardToken] = block.timestamp + _rewardDuration;
        emit RewardAdded(_rewardToken, _rewardAmount, _rewardDuration);
    }

    function _rewardPerToken(address _rewardToken, uint256 _totalSupply) internal view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored[_rewardToken];
        }

        uint256 _timeSinceLastUpdate = lastTimeRewardApplicable(_rewardToken) - lastUpdateTime[_rewardToken];
        uint256 _rewardsSinceLastUpdate = _timeSinceLastUpdate * rewardRates[_rewardToken];
        uint256 _rewardsPerTokenSinceLastUpdate = (_rewardsSinceLastUpdate * 1e18) / _totalSupply;
        return rewardPerTokenStored[_rewardToken] + _rewardsPerTokenSinceLastUpdate;
    }

    function _updateReward(
        address _rewardToken,
        address _account,
        uint256 _totalSupply,
        uint256 _balance
    ) internal {
        uint256 _rewardPerTokenStored = _rewardPerToken(_rewardToken, _totalSupply);
        rewardPerTokenStored[_rewardToken] = _rewardPerTokenStored;
        lastUpdateTime[_rewardToken] = lastTimeRewardApplicable(_rewardToken);
        if (_account != address(0)) {
            rewards[_rewardToken][_account] = _claimable(_rewardToken, _account, _totalSupply, _balance);
            userRewardPerTokenPaid[_rewardToken][_account] = _rewardPerTokenStored;
        }
    }
}
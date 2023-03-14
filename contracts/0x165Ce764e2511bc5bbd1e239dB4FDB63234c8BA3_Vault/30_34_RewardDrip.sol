// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IRewardDrip.sol";
import "./VaultBase.sol";

import "../external/@openzeppelin/utils/SafeCast.sol";
import "../external/@openzeppelin/security/ReentrancyGuard.sol";
import "../libraries/Math.sol";

/**
 * @notice Implementation of the {IRewardDrip} interface.
 *
 * @dev
 * An adaptation of the Synthetix StakingRewards contract to support multiple tokens:
 *
 * https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol
 *
 * Instead of storing the values of the StakingRewards contract at the contract level,
 * they are stored in a struct that is mapped to depending on the reward token instead.
 */
abstract contract RewardDrip is IRewardDrip, ReentrancyGuard, VaultBase {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    /// @notice Multiplier used when dealing reward calculations
    uint256 constant private REWARD_ACCURACY = 1e18;

    /* ========== STATE VARIABLES ========== */

    /// @notice All reward tokens supported by the contract
    mapping(uint256 => IERC20) public rewardTokens;

    /// @notice Vault reward token incentive configuration
    mapping(IERC20 => RewardConfiguration) public rewardConfiguration;

    /// @notice Blacklisted force-removed tokens
    mapping(IERC20 => bool) public override tokenBlacklist;

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable(IERC20 token)
        public
        view
        returns (uint32)
    {
        return uint32(Math.min(block.timestamp, rewardConfiguration[token].periodFinish));
    }

    function rewardPerToken(IERC20 token) public view returns (uint224) {
        RewardConfiguration storage config = rewardConfiguration[token];

        if (totalInstantDeposit == 0)
            return config.rewardPerTokenStored;
            
        uint256 timeDelta = lastTimeRewardApplicable(token) - config.lastUpdateTime;

        if (timeDelta == 0)
            return config.rewardPerTokenStored;

        return
            SafeCast.toUint224(
                config.rewardPerTokenStored + 
                    ((timeDelta
                        * config.rewardRate)
                        / totalInstantDeposit)
            );
    }

    function earned(IERC20 token, address account)
        public
        view
        returns (uint256)
    {
        RewardConfiguration storage config = rewardConfiguration[token];

        uint256 userShares = users[account].instantDeposit;

        if (userShares == 0)
            return config.rewards[account];
        
        uint256 userRewardPerTokenPaid = config.userRewardPerTokenPaid[account];

        return
            ((userShares * 
                (rewardPerToken(token) - userRewardPerTokenPaid))
                / REWARD_ACCURACY)
                + config.rewards[account];
    }

    function getRewardForDuration(IERC20 token)
        external
        view
        returns (uint256)
    {
        RewardConfiguration storage config = rewardConfiguration[token];
        return uint256(config.rewardRate) * config.rewardsDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getRewards(IERC20[] memory tokens) external nonReentrant {
        for (uint256 i; i < tokens.length; i++) {
            _getReward(tokens[i], msg.sender);
        }
    }

    function getActiveRewards(address account) external override onlyController nonReentrant {
        uint256 _rewardTokensCount = rewardTokensCount;
        for (uint256 i; i < _rewardTokensCount; i++) {
            _getReward(rewardTokens[i], account);
        }
    }

    function _getReward(IERC20 token, address account)
        internal
        updateReward(token, account)
    {
        RewardConfiguration storage config = rewardConfiguration[token];

        require(
            config.rewardsDuration != 0,
            "BTK"
        );

        uint256 reward = config.rewards[account];
        if (reward > 0) {
            config.rewards[account] = 0;
            token.safeTransfer(account, reward);
            emit RewardPaid(token, account, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Allows a new token to be added to the reward system
     *
     * @dev
     * Emits an {TokenAdded} event indicating the newly added reward token
     * and configuration
     *
     * Requirements:
     *
     * - the caller must be the reward distributor
     * - the reward duration must be non-zero
     * - the token must not have already been added
     *
     */
    function addToken(
        IERC20 token,
        uint32 rewardsDuration,
        uint256 reward
    ) external onlyVaultOwnerOrSpoolOwner exceptUnderlying(token) {
        RewardConfiguration storage config = rewardConfiguration[token];

        require(!tokenBlacklist[token], "TOBL");
        require(
            rewardsDuration != 0 &&
            config.lastUpdateTime == 0,
            "BCFG"
        );
        require(
            rewardTokensCount <= 5,
            "TMAX"
        );

        rewardTokens[rewardTokensCount] = token;
        rewardTokensCount++;

        config.rewardsDuration = rewardsDuration;

        if (reward > 0) {
            _notifyRewardAmount(token, reward);
        }
    }

    function notifyRewardAmount(IERC20 token, uint256 reward, uint32 rewardsDuration)
    external
    onlyVaultOwnerOrSpoolOwner
    {
        rewardConfiguration[token].rewardsDuration = rewardsDuration;
        _notifyRewardAmount(token, reward);
    }

    function _notifyRewardAmount(IERC20 token, uint256 reward)
        private
        updateReward(token, address(0))
    {
        RewardConfiguration storage config = rewardConfiguration[token];

        require(
            config.rewardPerTokenStored + (reward * REWARD_ACCURACY) <= type(uint192).max,
            "RTB"
        );

        token.safeTransferFrom(msg.sender, address(this), reward);
        uint32 newPeriodFinish = uint32(block.timestamp) + config.rewardsDuration;

        if (block.timestamp >= config.periodFinish) {
            config.rewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY) / config.rewardsDuration);
            emit RewardAdded(token, reward, config.rewardsDuration);
        } else {
            // If extending or adding additional rewards,
            // cannot set new finish time to be less than previously configured
            require(config.periodFinish <= newPeriodFinish, "PFS");
            uint256 remaining = config.periodFinish - block.timestamp;
            uint256 leftover = remaining * config.rewardRate;
            uint192 newRewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY + leftover) / config.rewardsDuration);
        
            require(
                newRewardRate >= config.rewardRate,
                "LRR"
            );

            config.rewardRate = newRewardRate;
            emit RewardExtended(token, reward, leftover, config.rewardsDuration, newPeriodFinish);
        }

        config.lastUpdateTime = uint32(block.timestamp);
        config.periodFinish = newPeriodFinish;
    }

    // End rewards emission earlier
    function updatePeriodFinish(IERC20 token, uint32 timestamp)
        external
        onlyOwner
        updateReward(token, address(0))
    {
        if (rewardConfiguration[token].lastUpdateTime > timestamp) {
            rewardConfiguration[token].periodFinish = rewardConfiguration[token].lastUpdateTime;
        } else {
            rewardConfiguration[token].periodFinish = timestamp;
        }

        emit PeriodFinishUpdated(token, rewardConfiguration[token].periodFinish);
    }

    /**
     * @notice Claim reward tokens
     * @dev
     * This is meant to be an emergency function to claim reward tokens.
     * Users that have not claimed yet will not be able to claim as
     * the rewards will be removed.
     *
     * Requirements:
     *
     * - the caller must be Spool DAO
     * - cannot claim vault underlying token
     * - cannot only execute if the reward finished
     *
     * @param token Token address to remove
     * @param amount Amount of tokens to claim
     */
    function claimFinishedRewards(IERC20 token, uint256 amount) external onlyOwner exceptUnderlying(token) onlyFinished(token) {
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Force remove reward from vault rewards configuration.
     * @dev This is meant to be an emergency function if a reward token breaks.
     *
     * Requirements:
     *
     * - the caller must be Spool DAO
     *
     * @param token Token address to remove
     */
    function forceRemoveReward(IERC20 token) external onlyOwner {
        tokenBlacklist[token] = true;
        _removeReward(token);

        delete rewardConfiguration[token];
    }

    /**
     * @notice Remove reward from vault rewards configuration.
     * @dev
     * Used to sanitize vault and save on gas, after the reward has ended.
     * Users will be able to claim rewards 
     *
     * Requirements:
     *
     * - the caller must be the spool owner or Spool DAO
     * - cannot claim vault underlying token
     * - cannot only execute if the reward finished
     *
     * @param token Token address to remove
     */
    function removeReward(IERC20 token) 
        external
        onlyVaultOwnerOrSpoolOwner
        onlyFinished(token)
        updateReward(token, address(0))
    {
        _removeReward(token);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Syncs rewards across all tokens of the system
     *
     * This function is meant to be invoked every time the instant deposit
     * of a user changes.
     */
    function _updateRewards(address account) private {
        uint256 _rewardTokensCount = rewardTokensCount;
        
        for (uint256 i; i < _rewardTokensCount; i++)
            _updateReward(rewardTokens[i], account);
    }

    function _updateReward(IERC20 token, address account) private {
        RewardConfiguration storage config = rewardConfiguration[token];
        config.rewardPerTokenStored = rewardPerToken(token);
        config.lastUpdateTime = lastTimeRewardApplicable(token);
        if (account != address(0)) {
            config.rewards[account] = earned(token, account);
            config.userRewardPerTokenPaid[account] = config
                .rewardPerTokenStored;
        }
    }

    function _removeReward(IERC20 token) private {
        uint256 _rewardTokensCount = rewardTokensCount;
        for (uint256 i; i < _rewardTokensCount; i++) {
            if (rewardTokens[i] == token) {
                rewardTokens[i] = rewardTokens[_rewardTokensCount - 1];

                delete rewardTokens[_rewardTokensCount - 1];
                rewardTokensCount--;
                emit RewardRemoved(token);

                break;
            }
        }
    }

    function _exceptUnderlying(IERC20 token) private view {
        require(
            token != _underlying(),
            "NUT"
        );
    }

    function _onlyFinished(IERC20 token) private view {
        require(
            block.timestamp > rewardConfiguration[token].periodFinish,
            "RNF"
        );
    }

    /**
    * @notice Ensures that the caller is the controller
     */
    function _onlyController() private view {
        require(
            msg.sender == address(controller),
            "OCTRL"
        );
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(IERC20 token, address account) {
        _updateReward(token, account);
        _;
    }

    modifier updateRewards() {
        _updateRewards(msg.sender);
        _;
    }

    modifier exceptUnderlying(IERC20 token) {
        _exceptUnderlying(token);
        _;
    }

    modifier onlyFinished(IERC20 token) {
        _onlyFinished(token);
        _;
    }

    /**
     * @notice Throws if called by anyone else other than the controller
     */
    modifier onlyController() {
        _onlyController();
        _;
    }
}
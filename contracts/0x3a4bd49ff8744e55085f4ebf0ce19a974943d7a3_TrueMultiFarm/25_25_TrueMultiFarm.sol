// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Ownable} from "Ownable.sol";
import {Initializable} from "Initializable.sol";

import {ITrueDistributor} from "ITrueDistributor.sol";
import {ITrueMultiFarm} from "ITrueMultiFarm.sol";
import {Upgradeable} from "Upgradeable.sol";

/**
 * @title TrueMultiFarm
 * @notice Deposit liquidity tokens to earn TRU rewards over time
 * @dev Staking pool where tokens are staked for TRU rewards
 * A Distributor contract decides how much TRU all farms in total can earn over time
 * Calling setShare() by owner decides ratio of rewards going to respective token farms
 * You can think of this contract as of a farm that is a distributor to the multiple other farms
 * A share of a farm in the multifarm is it's stake
 */

contract TrueMultiFarm is ITrueMultiFarm, Upgradeable {
    using SafeERC20 for IERC20;

    uint256 private constant PRECISION = 1e30;

    struct Stakes {
        uint256 totalStaked;
        mapping(address => uint256) staked;
    }

    struct FarmRewards {
        uint256 cumulativeRewardPerShare;
        uint256 unclaimedRewards;
        mapping(address => uint256) previousCumulatedRewardPerShare;
    }

    struct StakerRewards {
        uint256 cumulativeRewardPerToken;
        mapping(address => uint256) previousCumulatedRewardPerToken;
    }

    struct RewardDistribution {
        ITrueDistributor distributor;
        Stakes shares;
        FarmRewards farmRewards;
    }

    // stakedToken => stake info
    mapping(IERC20 => Stakes) public stakes;

    // rewardToken => reward info
    mapping(IERC20 => RewardDistribution) rewardDistributions;

    // stakedToken => rewardToken[]
    mapping(IERC20 => IERC20[]) public rewardsAvailable;

    // rewardToken -> stakedToken -> Rewards
    mapping(IERC20 => mapping(IERC20 => StakerRewards)) public stakerRewards;

    // rewardToken => undistributedRewards
    mapping(IERC20 => uint256) public undistributedRewards;

    IERC20[] public rewardTokens;

    function initialize() external initializer {
        __Upgradeable_init(msg.sender);
    }

    /**
     * @dev Emitted when an account stakes
     * @param who Account staking
     * @param amountStaked Amount of tokens staked
     */
    event Stake(IERC20 indexed token, address indexed who, uint256 amountStaked);

    /**
     * @dev Emitted when an account unstakes
     * @param who Account unstaking
     * @param amountUnstaked Amount of tokens unstaked
     */
    event Unstake(IERC20 indexed token, address indexed who, uint256 amountUnstaked);

    /**
     * @dev Emitted when an account claims TRU rewards
     * @param who Account claiming
     * @param amountClaimed Amount of TRU claimed
     */
    event Claim(IERC20 indexed token, address indexed who, uint256 amountClaimed);

    event DistributorAdded(IERC20 indexed rewardToken, ITrueDistributor indexed distributor);
    event DistributorRemoved(IERC20 indexed rewardToken);
    event SharesChanged(IERC20 indexed rewardToken, IERC20[] stakedTokens, uint256[] updatedShares);

    /**
     * @dev Update all rewards associated with the token and msg.sender
     */
    modifier update(IERC20 token) {
        IERC20[] memory _rewardsAvailable = rewardsAvailable[token];
        uint256 _rewardsAvailableLength = _rewardsAvailable.length;

        for (uint256 i; i < _rewardsAvailableLength; i++) {
            _distribute(_rewardsAvailable[i]);
        }
        updateRewards(token);
        _;
    }

    function getDistributor(IERC20 rewardToken) external view returns (ITrueDistributor) {
        return rewardDistributions[rewardToken].distributor;
    }

    function getRewardTokens() external view returns (IERC20[] memory) {
        return rewardTokens;
    }

    function getShares(IERC20 rewardToken, IERC20 stakedToken) external view returns (uint256) {
        return rewardDistributions[rewardToken].shares.staked[address(stakedToken)];
    }

    function getTotalShares(IERC20 rewardToken) external view returns (uint256) {
        return rewardDistributions[rewardToken].shares.totalStaked;
    }

    function getAvailableRewardsForToken(IERC20 stakedToken) external view returns (IERC20[] memory) {
        return rewardsAvailable[stakedToken];
    }

    /**
     * @dev How much is staked by staker on token farm
     */
    function staked(IERC20 token, address staker) external view returns (uint256) {
        return stakes[token].staked[staker];
    }

    function addDistributor(ITrueDistributor distributor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(distributor.farm() == address(this), "TrueMultiFarm: Distributor farm is not set");
        IERC20 rewardToken = distributor.trustToken();
        if (address(rewardDistributions[rewardToken].distributor) == address(0)) {
            rewardTokens.push(rewardToken);
        }
        rewardDistributions[rewardToken].distributor = distributor;

        emit DistributorAdded(rewardToken, distributor);
    }

    function removeDistributor(IERC20 rewardToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _distribute(rewardToken);
        uint256 rewardTokensLength = rewardTokens.length;

        for (uint256 i = 0; i < rewardTokensLength; i++) {
            if (rewardTokens[i] == rewardToken) {
                rewardTokens[i] = rewardTokens[rewardTokensLength - 1];
                rewardTokens.pop();
                break;
            }
        }

        delete rewardDistributions[rewardToken].distributor;

        emit DistributorRemoved(rewardToken);
    }

    /**
     * @dev Stake tokens for TRU rewards.
     * Also claims any existing rewards.
     * @param amount Amount of tokens to stake
     */
    function stake(IERC20 token, uint256 amount) external override update(token) {
        _claimAll(token);
        stakes[token].staked[msg.sender] += amount;
        stakes[token].totalStaked += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Stake(token, msg.sender, amount);
    }

    /**
     * @dev Remove staked tokens
     * @param amount Amount of tokens to unstake
     */
    function unstake(IERC20 token, uint256 amount) external override update(token) {
        _claimAll(token);
        _unstake(token, amount);
    }

    /**
     * @dev Claim all rewards
     */
    function claim(IERC20[] calldata stakedTokens) external override {
        uint256 stakedTokensLength = stakedTokens.length;

        distribute();
        for (uint256 i = 0; i < stakedTokensLength; i++) {
            updateRewards(stakedTokens[i]);
        }
        for (uint256 i = 0; i < stakedTokensLength; i++) {
            _claimAll(stakedTokens[i]);
        }
    }

    /**
     * @dev Claim rewardTokens
     */
    function claim(IERC20[] calldata stakedTokens, IERC20[] calldata rewards) external {
        uint256 stakedTokensLength = stakedTokens.length;
        uint256 rewardTokensLength = rewards.length;

        for (uint256 i = 0; i < rewardTokensLength; i++) {
            _distribute(rewards[i]);
        }
        for (uint256 i = 0; i < stakedTokensLength; i++) {
            updateRewards(stakedTokens[i], rewards);
        }
        for (uint256 i = 0; i < stakedTokensLength; i++) {
            _claim(stakedTokens[i], rewards);
        }
    }

    /**
     * @dev Unstake amount and claim rewards
     */
    function exit(IERC20[] calldata tokens) external override {
        distribute();

        uint256 tokensLength = tokens.length;

        for (uint256 i = 0; i < tokensLength; i++) {
            updateRewards(tokens[i]);
        }
        for (uint256 i = 0; i < tokensLength; i++) {
            _claimAll(tokens[i]);
            _unstake(tokens[i], stakes[tokens[i]].staked[msg.sender]);
        }
    }

    // Warning: calling this method will nullify your rewards. Never call it unless you're sure what you are doing!
    function emergencyExit(IERC20 stakedToken) external {
        _unstake(stakedToken, stakes[stakedToken].staked[msg.sender]);
    }

    /*
     * What proportional share of rewards get distributed to this token?
     * The denominator is visible in the public `shares()` view.
     */
    function getShare(IERC20 rewardToken, IERC20 stakedToken) external view returns (uint256) {
        return rewardDistributions[rewardToken].shares.staked[address(stakedToken)];
    }

    /**
     * @dev Set shares for farms
     * Example: setShares([DAI, USDC], [1, 2]) will ensure that 33.(3)% of rewards will go to DAI farm and rest to USDC farm
     * If later setShares([DAI, TUSD], [2, 1]) will be called then shares of DAI will grow to 2, shares of USDC won't change and shares of TUSD will be 1
     * So this will give 40% of rewards going to DAI farm, 40% to USDC and 20% to TUSD
     * @param stakedTokens Token addresses
     * @param updatedShares share of the i-th token in the multifarm
     */
    function setShares(
        IERC20 rewardToken,
        IERC20[] calldata stakedTokens,
        uint256[] calldata updatedShares
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokensLength = stakedTokens.length;

        require(tokensLength == updatedShares.length, "TrueMultiFarm: Array lengths mismatch");
        _distribute(rewardToken);

        for (uint256 i = 0; i < tokensLength; i++) {
            _updateTokenFarmRewards(rewardToken, stakedTokens[i]);
        }

        Stakes storage shares = rewardDistributions[rewardToken].shares;

        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20 stakedToken = stakedTokens[i];
            uint256 oldStaked = shares.staked[address(stakedToken)];
            shares.staked[address(stakedToken)] = updatedShares[i];
            shares.totalStaked = shares.totalStaked - oldStaked + updatedShares[i];
            if (updatedShares[i] == 0) {
                _removeReward(rewardToken, stakedToken);
            } else if (oldStaked == 0) {
                rewardsAvailable[stakedToken].push(rewardToken);
            }
        }

        emit SharesChanged(rewardToken, stakedTokens, updatedShares);
    }

    function _removeReward(IERC20 rewardToken, IERC20 stakedToken) internal {
        IERC20[] storage rewardsAvailableForToken = rewardsAvailable[stakedToken];
        uint256 rewardsAvailableForTokenLength = rewardsAvailableForToken.length;

        for (uint256 i = 0; i < rewardsAvailableForTokenLength; i++) {
            if (rewardsAvailableForToken[i] == rewardToken) {
                rewardsAvailableForToken[i] = rewardsAvailableForToken[rewardsAvailableForTokenLength - 1];
                rewardsAvailableForToken.pop();
                return;
            }
        }
    }

    /**
     * @dev Internal unstake function
     * @param amount Amount of tokens to unstake
     */
    function _unstake(IERC20 token, uint256 amount) internal {
        require(amount <= stakes[token].staked[msg.sender], "TrueMultiFarm: Cannot withdraw amount bigger than available balance");
        stakes[token].staked[msg.sender] -= amount;
        stakes[token].totalStaked -= amount;

        token.safeTransfer(msg.sender, amount);
        emit Unstake(token, msg.sender, amount);
    }

    function _claimAll(IERC20 token) internal {
        IERC20[] memory rewards = rewardsAvailable[token];
        _claim(token, rewards);
    }

    function _claim(IERC20 stakedToken, IERC20[] memory rewards) internal {
        uint256 rewardsLength = rewards.length;

        for (uint256 i = 0; i < rewardsLength; i++) {
            IERC20 rewardToken = rewards[i];
            StakerRewards storage _stakerRewards = stakerRewards[rewardToken][stakedToken];

            uint256 rewardToClaim = 0;
            if (stakes[stakedToken].staked[msg.sender] > 0) {
                rewardToClaim = _nextReward(
                    _stakerRewards,
                    _stakerRewards.cumulativeRewardPerToken,
                    stakes[stakedToken].staked[msg.sender],
                    msg.sender
                );
            }
            _stakerRewards.previousCumulatedRewardPerToken[msg.sender] = _stakerRewards.cumulativeRewardPerToken;

            if (rewardToClaim == 0) {
                continue;
            }

            FarmRewards storage farmRewards = rewardDistributions[rewardToken].farmRewards;
            farmRewards.unclaimedRewards -= rewardToClaim;

            rewardToken.safeTransfer(msg.sender, rewardToClaim);
            emit Claim(stakedToken, msg.sender, rewardToClaim);
        }
    }

    function claimable(
        IERC20 rewardToken,
        IERC20 stakedToken,
        address account
    ) external view returns (uint256) {
        return _claimable(rewardToken, stakedToken, account);
    }

    function rescue(IERC20 rewardToken) external {
        uint256 amount = undistributedRewards[rewardToken];
        if (amount == 0) {
            return;
        }
        undistributedRewards[rewardToken] = 0;
        rewardDistributions[rewardToken].farmRewards.unclaimedRewards -= amount;
        rewardToken.safeTransfer(getRoleMember(DEFAULT_ADMIN_ROLE, 0), amount);
    }

    /**
     * @dev Distribute rewards from distributor and increase cumulativeRewardPerShare in Multifarm
     */
    function distribute() internal {
        uint256 rewardTokensLength = rewardTokens.length;

        for (uint256 i = 0; i < rewardTokensLength; i++) {
            _distribute(rewardTokens[i]);
        }
    }

    function _distribute(IERC20 rewardToken) internal {
        ITrueDistributor distributor = rewardDistributions[rewardToken].distributor;
        if (address(distributor) != address(0) && distributor.nextDistribution() > 0 && distributor.farm() == address(this)) {
            distributor.distribute();
        }
        _updateCumulativeRewardPerShare(rewardToken);
    }

    /**
     * @dev This function must be called before any change of token share in multifarm happens (e.g. before shares.totalStaked changes)
     * This will also update cumulativeRewardPerToken after distribution has happened
     * 1. Get total lifetime rewards as Balance of TRU plus total rewards that have already been claimed
     * 2. See how much reward we got since previous update (R)
     * 3. Increase cumulativeRewardPerToken by R/total shares
     */
    function _updateCumulativeRewardPerShare(IERC20 rewardToken) internal {
        FarmRewards storage farmRewards = rewardDistributions[rewardToken].farmRewards;
        uint256 newUnclaimedRewards = _rewardBalance(rewardToken);
        uint256 rewardSinceLastUpdate = (newUnclaimedRewards - farmRewards.unclaimedRewards) * PRECISION;

        // if there are sub farms increase their value per share
        uint256 totalStaked = rewardDistributions[rewardToken].shares.totalStaked;
        if (totalStaked > 0) {
            farmRewards.unclaimedRewards = newUnclaimedRewards;
            farmRewards.cumulativeRewardPerShare += rewardSinceLastUpdate / totalStaked;
        }
    }

    /**
     * @dev Update rewards for the farm on token and for the staker.
     * The function must be called before any modification of staker's stake and to update values when claiming rewards
     */
    function updateRewards(IERC20 stakedToken) internal {
        IERC20[] storage rewardsAvailableForToken = rewardsAvailable[stakedToken];
        uint256 rewardLength = rewardsAvailableForToken.length;

        for (uint256 i = 0; i < rewardLength; i++) {
            _updateTokenFarmRewards(rewardsAvailableForToken[i], stakedToken);
        }
    }

    function updateRewards(IERC20 stakedToken, IERC20[] memory rewards) internal {
        uint256 rewardLength = rewards.length;

        for (uint256 i = 0; i < rewardLength; i++) {
            _updateTokenFarmRewards(rewards[i], stakedToken);
        }
    }

    function _rewardBalance(IERC20 rewardToken) internal view returns (uint256) {
        return rewardToken.balanceOf(address(this)) - stakes[rewardToken].totalStaked;
    }

    function _updateTokenFarmRewards(IERC20 rewardToken, IERC20 stakedToken) internal {
        RewardDistribution storage distribution = rewardDistributions[rewardToken];
        FarmRewards storage farmRewards = distribution.farmRewards;
        uint256 totalStaked = stakes[stakedToken].totalStaked;
        uint256 cumulativeRewardPerShareChange = farmRewards.cumulativeRewardPerShare -
            farmRewards.previousCumulatedRewardPerShare[address(stakedToken)];

        if (totalStaked > 0) {
            stakerRewards[rewardToken][stakedToken].cumulativeRewardPerToken +=
                (cumulativeRewardPerShareChange * distribution.shares.staked[address(stakedToken)]) /
                totalStaked;
        } else {
            undistributedRewards[rewardToken] +=
                (cumulativeRewardPerShareChange * distribution.shares.staked[address(stakedToken)]) /
                PRECISION;
        }
        farmRewards.previousCumulatedRewardPerShare[address(stakedToken)] = farmRewards.cumulativeRewardPerShare;
    }

    function _claimable(
        IERC20 rewardToken,
        IERC20 stakedToken,
        address account
    ) internal view returns (uint256) {
        Stakes storage shares = rewardDistributions[rewardToken].shares;
        FarmRewards storage farmRewards = rewardDistributions[rewardToken].farmRewards;
        StakerRewards storage _stakerRewards = stakerRewards[rewardToken][stakedToken];
        ITrueDistributor distributor = rewardDistributions[rewardToken].distributor;

        uint256 stakedAmount = stakes[stakedToken].staked[account];
        if (stakedAmount == 0) {
            return 0;
        }

        uint256 rewardSinceLastUpdate = _rewardSinceLastUpdate(farmRewards, distributor, rewardToken);
        uint256 nextCumulativeRewardPerToken = _nextCumulativeReward(
            farmRewards,
            _stakerRewards,
            shares,
            rewardSinceLastUpdate,
            address(stakedToken)
        );
        return _nextReward(_stakerRewards, nextCumulativeRewardPerToken, stakedAmount, account);
    }

    function _rewardSinceLastUpdate(
        FarmRewards storage farmRewards,
        ITrueDistributor distributor,
        IERC20 rewardToken
    ) internal view returns (uint256) {
        uint256 pending = 0;
        if (address(distributor) != address(0) && distributor.farm() == address(this)) {
            pending = distributor.nextDistribution();
        }

        uint256 newUnclaimedRewards = _rewardBalance(rewardToken) + pending;
        return newUnclaimedRewards - farmRewards.unclaimedRewards;
    }

    function _nextCumulativeReward(
        FarmRewards storage farmRewards,
        StakerRewards storage _stakerRewards,
        Stakes storage shares,
        uint256 rewardSinceLastUpdate,
        address stakedToken
    ) internal view returns (uint256) {
        uint256 cumulativeRewardPerShare = farmRewards.cumulativeRewardPerShare;
        uint256 nextCumulativeRewardPerToken = _stakerRewards.cumulativeRewardPerToken;
        uint256 totalStaked = stakes[IERC20(stakedToken)].totalStaked;
        if (shares.totalStaked > 0) {
            cumulativeRewardPerShare += (rewardSinceLastUpdate * PRECISION) / shares.totalStaked;
        }
        if (totalStaked > 0) {
            nextCumulativeRewardPerToken +=
                (shares.staked[stakedToken] * (cumulativeRewardPerShare - farmRewards.previousCumulatedRewardPerShare[stakedToken])) /
                totalStaked;
        }
        return nextCumulativeRewardPerToken;
    }

    function _nextReward(
        StakerRewards storage _stakerRewards,
        uint256 _cumulativeRewardPerToken,
        uint256 _stake,
        address _account
    ) internal view returns (uint256) {
        return ((_cumulativeRewardPerToken - _stakerRewards.previousCumulatedRewardPerToken[_account]) * _stake) / PRECISION;
    }
}
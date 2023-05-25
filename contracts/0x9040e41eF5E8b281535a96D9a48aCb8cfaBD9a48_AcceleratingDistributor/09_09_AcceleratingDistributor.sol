// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * @notice Across token distribution contract. Contract is inspired by Synthetix staking contract and Ampleforth geyser.
 * Stakers start by earning their pro-rata share of a baseEmissionRate per second which increases based on how long
 * they have staked in the contract, up to a max emission rate of baseEmissionRate * maxMultiplier. Multiple LP tokens
 * can be staked in this contract enabling depositors to batch stake and claim via multicall. Note that this contract is
 * only compatible with standard ERC20 tokens, and not tokens that charge fees on transfers, dynamically change
 * balance, or have double entry-points. It's up to the contract owner to ensure they only add supported tokens.
 */

contract AcceleratingDistributor is ReentrancyGuard, Ownable, Multicall {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;

    // Each User deposit is tracked with the information below.
    struct UserDeposit {
        uint256 cumulativeBalance;
        uint256 averageDepositTime;
        uint256 rewardsAccumulatedPerToken;
        uint256 rewardsOutstanding;
    }

    struct StakingToken {
        bool enabled;
        uint256 baseEmissionRate;
        uint256 maxMultiplier;
        uint256 secondsToMaxMultiplier;
        uint256 cumulativeStaked;
        uint256 rewardPerTokenStored;
        uint256 lastUpdateTime;
        mapping(address => UserDeposit) stakingBalances;
    }

    mapping(address => StakingToken) public stakingTokens;

    modifier onlyEnabled(address stakedToken) {
        require(stakingTokens[stakedToken].enabled, "stakedToken not enabled");
        _;
    }

    modifier onlyInitialized(address stakedToken) {
        require(stakingTokens[stakedToken].lastUpdateTime != 0, "stakedToken not initialized");
        _;
    }

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**************************************
     *               EVENTS               *
     **************************************/

    event TokenConfiguredForStaking(
        address indexed token,
        bool enabled,
        uint256 baseEmissionRate,
        uint256 maxMultiplier,
        uint256 secondsToMaxMultiplier,
        uint256 lastUpdateTime
    );
    event RecoverToken(address indexed token, uint256 amount);
    event Stake(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 averageDepositTime,
        uint256 cumulativeBalance,
        uint256 tokenCumulativeStaked
    );
    event Unstake(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 remainingCumulativeBalance,
        uint256 tokenCumulativeStaked
    );
    event RewardsWithdrawn(
        address indexed token,
        address indexed user,
        uint256 rewardsToSend,
        uint256 tokenLastUpdateTime,
        uint256 tokenRewardPerTokenStored,
        uint256 userRewardsOutstanding,
        uint256 userRewardsPaidPerToken
    );
    event Exit(address indexed token, address indexed user, uint256 tokenCumulativeStaked);

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Enable a token for staking.
     * @dev The owner should ensure that the token enabled is a standard ERC20 token to ensure correct functionality.
     * @param stakedToken The address of the token that can be staked.
     * @param enabled Whether the token is enabled for staking.
     * @param baseEmissionRate The base emission rate for staking the token. This is split pro-rata between all users.
     * @param maxMultiplier The maximum multiplier for staking which increases your rewards the longer you stake.
     * @param secondsToMaxMultiplier The number of seconds needed to stake to reach the maximum multiplier.
     */
    function configureStakingToken(
        address stakedToken,
        bool enabled,
        uint256 baseEmissionRate,
        uint256 maxMultiplier,
        uint256 secondsToMaxMultiplier
    ) external onlyOwner {
        // Validate input to ensure system stability and avoid unexpected behavior. Note we dont place a lower bound on
        // the baseEmissionRate. If this value is less than 1e18 then you will slowly loose your staking rewards over time.
        // Because of the way balances are managed, the staked token cannot be the reward token. Otherwise, reward
        // payouts could eat into user balances. We choose not to constrain `maxMultiplier` to be > 1e18 so that
        // admin can choose to allow decreasing emissions over time. This is not the intended use case, but we see no
        // benefit to removing this additional flexibility. If set < 1e18, then user's rewards outstanding will
        // decrease over time. Incentives for stakers would look different if `maxMultiplier` were set < 1e18
        require(stakedToken != address(rewardToken), "Staked token is reward token");
        require(maxMultiplier < 1e36, "maxMultiplier can not be set too large");
        require(secondsToMaxMultiplier > 0, "secondsToMaxMultiplier must be greater than 0");
        require(baseEmissionRate < 1e27, "baseEmissionRate can not be set too large");

        StakingToken storage stakingToken = stakingTokens[stakedToken];

        // If this token is already initialized, make sure we update the rewards before modifying any params.
        if (stakingToken.lastUpdateTime != 0) _updateReward(stakedToken, address(0));

        stakingToken.enabled = enabled;
        stakingToken.baseEmissionRate = baseEmissionRate;
        stakingToken.maxMultiplier = maxMultiplier;
        stakingToken.secondsToMaxMultiplier = secondsToMaxMultiplier;
        stakingToken.lastUpdateTime = getCurrentTime();

        emit TokenConfiguredForStaking(
            stakedToken,
            enabled,
            baseEmissionRate,
            maxMultiplier,
            secondsToMaxMultiplier,
            stakingToken.lastUpdateTime
        );
    }

    /**
     * @notice Enables the owner to recover tokens dropped onto the contract. This could be used to remove unclaimed
     * staking rewards or recover excess LP tokens that were inadvertently dropped onto the contract. Importantly, the
     * contract will only let the owner recover staked excess tokens above what the contract thinks it should have. i.e
     * the owner cant use this method to steal staked tokens, only recover excess ones mistakenly sent to the contract.
     * @param token The address of the token to skim.
     */
    function recoverToken(address token) external onlyOwner {
        // If the token is an enabled staking token then we want to preform a skim action where we send back any extra
        // tokens that are not accounted for in the cumulativeStaked variable. This lets the owner recover extra tokens
        // sent to the contract that were not explicitly staked. if the token is not enabled for staking then we simply
        // send back the full amount of tokens that the contract has.
        uint256 amount = IERC20(token).balanceOf(address(this));
        if (stakingTokens[token].lastUpdateTime != 0) amount -= stakingTokens[token].cumulativeStaked;
        require(amount > 0, "Can't recover 0 tokens");
        IERC20(token).safeTransfer(owner(), amount);
        emit RecoverToken(token, amount);
    }

    /**************************************
     *          STAKER FUNCTIONS          *
     **************************************/

    /**
     * @notice Stake tokens for rewards.
     * @dev The caller of this function must approve this contract to spend amount of stakedToken.
     * @param stakedToken The address of the token to stake.
     * @param amount The amount of the token to stake.
     */
    function stake(address stakedToken, uint256 amount) external nonReentrant onlyEnabled(stakedToken) {
        _stake(stakedToken, amount, msg.sender);
    }

    /**
     * @notice Stake tokens for rewards on behalf of `beneficiary`.
     * @dev The caller of this function must approve this contract to spend amount of stakedToken.
     * @dev The caller of this function is effectively donating their tokens to the beneficiary. The beneficiary
     * can then unstake or claim rewards as they wish.
     * @param stakedToken The address of the token to stake.
     * @param amount The amount of the token to stake.
     * @param beneficiary User that caller wants to stake on behalf of.
     */
    function stakeFor(
        address stakedToken,
        uint256 amount,
        address beneficiary
    ) external nonReentrant onlyEnabled(stakedToken) {
        _stake(stakedToken, amount, beneficiary);
    }

    /**
     * @notice Withdraw staked tokens.
     * @param stakedToken The address of the token to withdraw.
     * @param amount The amount of the token to withdraw.
     */
    function unstake(address stakedToken, uint256 amount) public nonReentrant onlyInitialized(stakedToken) {
        _updateReward(stakedToken, msg.sender);
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[msg.sender];

        // Note: these will revert if underflow so you cant unstake more than your cumulativeBalance.
        userDeposit.cumulativeBalance -= amount;
        stakingTokens[stakedToken].cumulativeStaked -= amount;

        IERC20(stakedToken).safeTransfer(msg.sender, amount);

        emit Unstake(
            stakedToken,
            msg.sender,
            amount,
            userDeposit.cumulativeBalance,
            stakingTokens[stakedToken].cumulativeStaked
        );
    }

    /**
     * @notice Get entitled rewards for the staker.
     * @dev Calling this method will reset the caller's reward multiplier.
     * @param stakedToken The address of the token to get rewards for.
     */
    function withdrawReward(address stakedToken) public nonReentrant onlyInitialized(stakedToken) {
        _updateReward(stakedToken, msg.sender);
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[msg.sender];

        uint256 rewardsToSend = userDeposit.rewardsOutstanding;
        if (rewardsToSend > 0) {
            userDeposit.rewardsOutstanding = 0;
            userDeposit.averageDepositTime = getCurrentTime();
            rewardToken.safeTransfer(msg.sender, rewardsToSend);
        }

        emit RewardsWithdrawn(
            stakedToken,
            msg.sender,
            rewardsToSend,
            stakingTokens[stakedToken].lastUpdateTime,
            stakingTokens[stakedToken].rewardPerTokenStored,
            userDeposit.rewardsOutstanding,
            userDeposit.rewardsAccumulatedPerToken
        );
    }

    /**
     * @notice Exits a staking position by unstaking and getting rewards. This totally exits the staking position.
     * @dev Calling this method will reset the caller's reward multiplier.
     * @param stakedToken The address of the token to get rewards for.
     */
    function exit(address stakedToken) external onlyInitialized(stakedToken) {
        _updateReward(stakedToken, msg.sender);
        unstake(stakedToken, stakingTokens[stakedToken].stakingBalances[msg.sender].cumulativeBalance);
        withdrawReward(stakedToken);

        emit Exit(stakedToken, msg.sender, stakingTokens[stakedToken].cumulativeStaked);
    }

    /**************************************
     *           VIEW FUNCTIONS           *
     **************************************/

    /**
     * @notice Returns the total staked for a given stakedToken.
     * @param stakedToken The address of the staked token to query.
     * @return uint256 Total amount staked of the stakedToken.
     */
    function getCumulativeStaked(address stakedToken) external view returns (uint256) {
        return stakingTokens[stakedToken].cumulativeStaked;
    }

    /**
     * @notice Returns all the information associated with a user's stake.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of user to query.
     * @return UserDeposit Struct with: {cumulativeBalance,averageDepositTime,rewardsAccumulatedPerToken,rewardsOutstanding}
     */
    function getUserStake(address stakedToken, address account) external view returns (UserDeposit memory) {
        return stakingTokens[stakedToken].stakingBalances[account];
    }

    /**
     * @notice Returns the base rewards per staked token for a given staking token. This factors in the last time
     * any internal logic was called on this contract to correctly attribute retroactive cumulative rewards.
     * @dev the value returned is represented by a uint256 with fixed precision of 18 decimals.
     * @param stakedToken The address of the staked token to query.
     * @return uint256 Total base reward per token that will be applied, pro-rata, to stakers.
     */
    function baseRewardPerToken(address stakedToken) public view returns (uint256) {
        StakingToken storage stakingToken = stakingTokens[stakedToken];
        if (stakingToken.cumulativeStaked == 0) return stakingToken.rewardPerTokenStored;

        return
            stakingToken.rewardPerTokenStored +
            ((getCurrentTime() - stakingToken.lastUpdateTime) * stakingToken.baseEmissionRate * 1e18) /
            stakingToken.cumulativeStaked;
    }

    /**
     * @notice Returns the multiplier applied to the base reward per staked token for a given staking token and account.
     * The longer a user stakes the higher their multiplier up to maxMultiplier for that given staking token.
     * any internal logic was called on this contract to correctly attribute retroactive cumulative rewards.
     * @dev the value returned is represented by a uint256 with fixed precision of 18 decimals.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     * @return uint256 User multiplier, applied to the baseRewardPerToken, when claiming rewards.
     */
    function getUserRewardMultiplier(address stakedToken, address account) public view returns (uint256) {
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[account];
        if (userDeposit.averageDepositTime == 0 || userDeposit.cumulativeBalance == 0) return 1e18;
        uint256 fractionOfMaxMultiplier = ((getTimeSinceAverageDeposit(stakedToken, account)) * 1e18) /
            stakingTokens[stakedToken].secondsToMaxMultiplier;

        // At maximum, the multiplier should be equal to the maxMultiplier.
        if (fractionOfMaxMultiplier > 1e18) fractionOfMaxMultiplier = 1e18;
        return 1e18 + (fractionOfMaxMultiplier * (stakingTokens[stakedToken].maxMultiplier - 1e18)) / (1e18);
    }

    /**
     * @notice Returns the total outstanding rewards entitled to a user for a given staking token. This factors in the
     * users staking duration (and therefore reward multiplier) and their pro-rata share of the total rewards.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     * @return uint256 Total outstanding rewards entitled to user.
     */
    function getOutstandingRewards(address stakedToken, address account) public view returns (uint256) {
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[account];

        uint256 userRewardMultiplier = getUserRewardMultiplier(stakedToken, account);

        uint256 newUserRewards = (userDeposit.cumulativeBalance *
            (baseRewardPerToken(stakedToken) - userDeposit.rewardsAccumulatedPerToken) *
            userRewardMultiplier) / (1e18 * 1e18);

        return newUserRewards + userDeposit.rewardsOutstanding;
    }

    /**
     * @notice Returns the time that has elapsed between the current time and the last users average deposit time.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     *@return uint256 Time, in seconds, between the users average deposit time and the current time.
     */
    function getTimeSinceAverageDeposit(address stakedToken, address account) public view returns (uint256) {
        return getCurrentTime() - stakingTokens[stakedToken].stakingBalances[account].averageDepositTime;
    }

    /**
     * @notice Returns a users new average deposit time, considering the addition of a new deposit. This factors in the
     * cumulative previous deposits, new deposit and time from the last deposit.
     * @param stakedToken The address of the staked token to query.
     * @param account The address of the user to query.
     * @return uint256 Average post deposit time, considering all deposits to date.
     */
    function getAverageDepositTimePostDeposit(
        address stakedToken,
        address account,
        uint256 amount
    ) public view returns (uint256) {
        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[account];
        if (amount == 0) return userDeposit.averageDepositTime;
        uint256 amountWeightedTime = (((amount * 1e18) / (userDeposit.cumulativeBalance + amount)) *
            (getTimeSinceAverageDeposit(stakedToken, account))) / 1e18;
        return userDeposit.averageDepositTime + amountWeightedTime;
    }

    /**************************************
     *         INTERNAL FUNCTIONS         *
     **************************************/

    // Update the internal counters for a given stakedToken and user.
    function _updateReward(address stakedToken, address account) internal {
        StakingToken storage stakingToken = stakingTokens[stakedToken];
        stakingToken.rewardPerTokenStored = baseRewardPerToken(stakedToken);
        stakingToken.lastUpdateTime = getCurrentTime();
        if (account != address(0)) {
            UserDeposit storage userDeposit = stakingToken.stakingBalances[account];
            userDeposit.rewardsOutstanding = getOutstandingRewards(stakedToken, account);
            userDeposit.rewardsAccumulatedPerToken = stakingToken.rewardPerTokenStored;
        }
    }

    function _stake(
        address stakedToken,
        uint256 amount,
        address staker
    ) internal {
        _updateReward(stakedToken, staker);

        UserDeposit storage userDeposit = stakingTokens[stakedToken].stakingBalances[staker];

        uint256 averageDepositTime = getAverageDepositTimePostDeposit(stakedToken, staker, amount);

        userDeposit.averageDepositTime = averageDepositTime;
        userDeposit.cumulativeBalance += amount;
        stakingTokens[stakedToken].cumulativeStaked += amount;

        IERC20(stakedToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Stake(
            stakedToken,
            staker,
            amount,
            averageDepositTime,
            userDeposit.cumulativeBalance,
            stakingTokens[stakedToken].cumulativeStaked
        );
    }
}
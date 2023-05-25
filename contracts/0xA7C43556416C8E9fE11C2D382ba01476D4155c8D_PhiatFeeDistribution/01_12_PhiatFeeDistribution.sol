// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../dependencies/openzeppelin/contracts/IERC20Capped.sol";
import "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../../dependencies/openzeppelin/contracts/Ownable.sol";
import "../../dependencies/governance/TreasuryOwnable.sol";
import "../../interfaces/IPhiatFeeDistribution.sol";
import "./ERC20Recoverable.sol";

contract PhiatFeeDistribution is
    IPhiatFeeDistribution,
    Ownable,
    TreasuryOwnable,
    ERC20Recoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20Capped;
    using SafeERC20 for IERC20;

    uint256 public constant override REWARD_RATE_PRECISION_ASSIST = 1e18;
    // Duration that rewards are streamed over
    uint256 public constant override REWARD_DURATION = 86400 * 7; // 1 week
    // Duration to unstake so that tokens are withdrawable
    uint256 public constant override UNSTAKE_DURATION = 86400 * 7 * 2; // 2 weeks
    // Duration to withdraw unstaked tokens
    uint256 public constant override WITHDRAW_DURATION = 86400 * 7; // 1 week

    IERC20Capped public immutable override stakingToken;
    uint256 public immutable override stakingTokenPrecision;
    uint256 public immutable override totalSupply; // staking token's total supply (cap)
    uint256 public override totalStakedSupply; // staking token's total staked supply
    address[] public tokens;
    // reward token -> TokenReward
    mapping(address => TokenReward) public tokenRewards;

    // user -> reward token -> amount
    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward (for total supply)
    // token's decimals are kept
    mapping(address => mapping(address => uint256)) private _userRewardPaid;
    // treasury reward is recorded in this contract's address - address(this)
    // should divide by REWARD_RATE_PRECISION_ASSIST to get true rewards (for individual user)
    // token's decimals are kept
    mapping(address => mapping(address => uint256)) private _userRewards;

    // user -> total staked balance (including unstaked and not withdrawn)
    mapping(address => uint256) private staked;
    // user -> TimedBalance(unstaked amount, withdraw time)
    mapping(address => TimedBalance) private unstaked;

    /* ========== CONSTRUCTOR ========== */

    constructor(address stakingToken_, address treasury_)
        Ownable()
        TreasuryOwnable(treasury_)
    {
        stakingToken = IERC20Capped(stakingToken_);
        stakingTokenPrecision = 10**IERC20Capped(stakingToken_).decimals();
        totalSupply = IERC20Capped(stakingToken_).cap();
    }

    /* ========== ADMIN CONFIGURATION ========== */

    // Add a new reward token to be distributed to stakers
    function addReward(address tokenAddress) external onlyOwner {
        require(
            tokenAddress != address(stakingToken),
            "PHIAT: Can not add staking token as reward token"
        );
        require(
            tokenRewards[tokenAddress].lastUpdateTime == 0,
            "PHIAT: Can not add existing reward token"
        );
        tokens.push(tokenAddress);
        tokenRewards[tokenAddress].lastUpdateTime = block.timestamp;
        tokenRewards[tokenAddress].periodFinish = block.timestamp;
    }

    function transferTreasury(address newTreasury)
        external
        override
        onlyTreasury
    {
        require(
            newTreasury != address(0),
            "TreasuryOwnable: new treasury is the zero address"
        );
        require(
            staked[newTreasury] == 0,
            "PHIAT: new treasury can not have staked tokens"
        );
        _transferTreasury(newTreasury);
    }

    /* ========== REWARD VIEWS ========== */

    function lastTimeRewardApplicable(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        // should only return periodFinish
        // when this is a new reward token
        // or when no new rewards have been collected for over REWARD_DURATION
        uint256 periodFinish = tokenRewards[tokenAddress].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward per token
    // token's decimals are kept
    // staking token's decimals are removed
    function rewardPerToken(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        return _reward(tokenAddress).div(totalSupply);
    }

    function getRewardForDuration(address tokenAddress)
        external
        view
        override
        returns (uint256)
    {
        return
            tokenRewards[tokenAddress].rewardRate.mul(REWARD_DURATION).div(
                REWARD_RATE_PRECISION_ASSIST
            );
    }

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account)
        external
        view
        override
        returns (RewardAmount[] memory rewards)
    {
        uint256 stakedBalance_;
        if (account == treasury()) {
            account = address(this);
            stakedBalance_ = totalSupply.sub(totalStakedSupply);
        } else {
            stakedBalance_ = staked[account];
        }

        uint256 length = tokens.length;
        rewards = new RewardAmount[](length);
        for (uint256 i = 0; i < length; i++) {
            rewards[i].token = tokens[i];
            rewards[i].amount = _earned(
                account,
                tokens[i],
                stakedBalance_,
                _reward(tokens[i])
            ).div(REWARD_RATE_PRECISION_ASSIST);
        }
        return rewards;
    }

    /* ========== STAKING VIEWS ========== */

    // Total staked balance of an account, including unstaked tokens that haven't been withdrawn
    function stakedBalance(address user)
        external
        view
        override
        returns (uint256 amount)
    {
        return staked[user];
    }

    // Total unstaked balance for an account (in the process of unstaking)
    function unstakedBalance(address user)
        external
        view
        override
        returns (TimedBalance memory balance)
    {
        balance = unstaked[user];
        if (balance.amount == 0) {
            // no record
        } else if (block.timestamp < balance.time) {
            // still unstaking
        } else {
            balance.amount = 0;
            balance.time = 0;
        }
        return balance;
    }

    // Total withdrawable balance for an account
    function withdrawableBalance(address user)
        external
        view
        override
        returns (TimedBalance memory balance)
    {
        balance = unstaked[user];
        if (balance.amount == 0) {
            // no record
        } else if (block.timestamp >= balance.time) {
            // can withdraw if not reaching expiration time
            balance.time = balance.time.add(WITHDRAW_DURATION); // calculate expiration time
            if (block.timestamp >= balance.time) {
                // reached expiration time
                balance.amount = 0;
                balance.time = 0;
            }
        } else {
            balance.amount = 0;
            balance.time = 0;
        }
        return balance;
    }

    /* ========== STAKING MANAGEMENT ========== */

    // Stake tokens to receive rewards
    function stake(uint256 amount) external {
        require(amount > 0, "PHIAT: Cannot stake 0");
        require(_msgSender() != treasury(), "PHIAT: treasury can not stake");
        _updateReward(_msgSender(), true);
        staked[_msgSender()] = staked[_msgSender()].add(amount);
        totalStakedSupply = totalStakedSupply.add(amount);
        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        emit Staked(_msgSender(), amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "PHIAT: Cannot unstake 0");
        TimedBalance memory balance = unstaked[_msgSender()];
        require(
            balance.amount == 0 ||
                block.timestamp >= balance.time.add(WITHDRAW_DURATION), // expired
            "PHIAT: Cannot perform multiple unstaking at the same time"
        );
        require(
            amount <= staked[_msgSender()],
            "PHIAT: Cannot unstake more than staked amount"
        );
        balance.amount = amount;
        balance.time = block.timestamp.add(UNSTAKE_DURATION);
        unstaked[_msgSender()] = balance; // will override previously expired unstaking
        emit Unstaked(_msgSender(), amount);
    }

    function cancelUnstake() external {
        TimedBalance memory balance = unstaked[_msgSender()];
        require(
            balance.amount > 0 && block.timestamp < balance.time, // unstaking not finished
            "PHIAT: No unstaking to cancel"
        );
        delete unstaked[_msgSender()];
        emit UnstakeCancelled(_msgSender());
    }

    // Withdraw all withdrawable tokens
    function withdraw() external {
        TimedBalance memory balance = unstaked[_msgSender()];
        require(
            balance.amount > 0 &&
                block.timestamp >= balance.time && // unstaking finished
                block.timestamp < balance.time.add(WITHDRAW_DURATION), // not expired
            "PHIAT: No withdrawable token"
        );
        _updateReward(_msgSender(), true);
        delete unstaked[_msgSender()];
        if (staked[_msgSender()] == balance.amount) {
            delete staked[_msgSender()];
        } else {
            staked[_msgSender()] = staked[_msgSender()].sub(balance.amount);
        }
        totalStakedSupply = totalStakedSupply.sub(balance.amount);
        stakingToken.safeTransfer(_msgSender(), balance.amount);
        emit Withdrawn(_msgSender(), balance.amount);
    }

    // Claim all pending staking rewards
    function getReward() public override {
        _updateReward(_msgSender(), false);
        _getReward();
    }

    /* ========== INTERNAL REWARD MANAGEMENT ========== */

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true reward
    // token's decimals are kept
    function _reward(address tokenAddress) internal view returns (uint256) {
        uint256 lastTimeRewardApplicable_ = lastTimeRewardApplicable(
            tokenAddress
        );
        if (
            lastTimeRewardApplicable_ ==
            tokenRewards[tokenAddress].lastUpdateTime
        ) {
            return tokenRewards[tokenAddress].rewardStored;
        } else {
            uint256 additionalReward = lastTimeRewardApplicable_
                .sub(tokenRewards[tokenAddress].lastUpdateTime)
                .mul(tokenRewards[tokenAddress].rewardRate);
            return
                tokenRewards[tokenAddress].rewardStored.add(additionalReward);
        }
    }

    // should divide by REWARD_RATE_PRECISION_ASSIST to get true earned rewards
    // token's decimals are kept
    function _earned(
        address account,
        address tokenAddress,
        uint256 stakedBalance_,
        uint256 reward
    ) internal view returns (uint256) {
        return
            stakedBalance_
                .mul(reward.sub(_userRewardPaid[account][tokenAddress]))
                .div(totalSupply)
                .add(_userRewards[account][tokenAddress]);
    }

    function _updateReward(address account, bool updateTreasury) internal {
        address thisAddress = address(this);
        uint256 treasuryBalance = totalSupply.sub(totalStakedSupply);
        if (account == treasury()) {
            // treasury info is saved in address(this) to make transferTreasury simpler
            account = thisAddress;
            updateTreasury = false; // no need to update treasury as a separate step
        }
        uint256 stakedBalance_ = account == thisAddress
            ? treasuryBalance
            : staked[account];
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            address token = tokens[i];
            TokenReward storage tokenReward = tokenRewards[token];

            uint256 reward = _reward(token);
            tokenReward.rewardStored = reward;
            tokenReward.lastUpdateTime = lastTimeRewardApplicable(token);

            // update account reward
            _userRewards[account][token] = _earned(
                account,
                token,
                stakedBalance_,
                reward
            );
            _userRewardPaid[account][token] = reward;
            if (updateTreasury) {
                // update treasury reward
                _userRewards[thisAddress][token] = _earned(
                    thisAddress,
                    token,
                    treasuryBalance,
                    reward
                );
                _userRewardPaid[thisAddress][token] = reward;
            }
        }
    }

    // every 24 hours treasury will check
    // if new rewards were sent to the contract or accrued via aToken interest
    // and collect treasury rewards
    function _getReward() internal {
        address account = _msgSender() == treasury()
            ? address(this)
            : _msgSender();
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            address token = tokens[i];
            uint256 reward = _userRewards[account][token].div(
                REWARD_RATE_PRECISION_ASSIST
            );
            TokenReward storage tokenReward = tokenRewards[token];
            uint256 tokenBalance = tokenReward.balance;
            uint256 currentBalance = IERC20(token).balanceOf(address(this));
            if (tokenBalance > currentBalance) {
                // current balance has a slight chance to be lower than stored balance
                // when no new rewards for a prolonged period,
                // and some existing rewards are collected
                // this is due to phToken's balanceOf using a scaling function
                // and therefore has a rounding issue
                tokenBalance = currentBalance;
            }
            if (
                tokenReward.periodFinish <=
                block.timestamp.add(REWARD_DURATION - 86400)
            ) {
                // update if progressed more than 1 day since last periodFinish update
                // or when token is newly added as reward token
                uint256 newlyCollectedRewards = currentBalance.sub(
                    tokenBalance
                );
                if (newlyCollectedRewards > 0) {
                    if (block.timestamp >= tokenReward.periodFinish) {
                        // token is newly added as reward token
                        tokenReward.rewardRate = newlyCollectedRewards
                            .mul(REWARD_RATE_PRECISION_ASSIST)
                            .div(REWARD_DURATION);
                    } else {
                        uint256 remainingTime = tokenReward.periodFinish.sub(
                            block.timestamp
                        ); // around 6 days
                        uint256 projectRewards = remainingTime.mul(
                            tokenReward.rewardRate
                        );
                        // use 1-day real and 6-day projection (current reward rate)
                        // to smooth our reward rate calculation
                        tokenReward.rewardRate = newlyCollectedRewards
                            .mul(REWARD_RATE_PRECISION_ASSIST)
                            .add(projectRewards)
                            .div(REWARD_DURATION);
                    }

                    tokenReward.lastUpdateTime = block.timestamp;
                    tokenReward.periodFinish = block.timestamp.add(
                        REWARD_DURATION
                    );
                    tokenBalance = currentBalance;
                }
            }
            if (tokenBalance < reward) {
                // again this may happen due to phToken balanceOf's rounding issue
                // under extreme circumstances mentioned above
                reward = tokenBalance;
                if (reward == 0) {
                    _userRewards[account][token] = 0;
                }
            }
            tokenReward.balance = tokenBalance.sub(reward);

            if (reward == 0) continue;
            _userRewards[account][token] = 0;
            IERC20(token).safeTransfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), token, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // support recovering ERC20 tokens except for staking tokens and reward tokens
    function recoverERC20(address tokenAddress) external onlyTreasury {
        require(
            tokenAddress != address(stakingToken),
            "PHIAT: Cannot recover staking token"
        );
        require(
            tokenRewards[tokenAddress].lastUpdateTime == 0,
            "PHIAT: Cannot recover reward token"
        );
        _recoverERC20(tokenAddress);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/PriceCalculator.sol";

contract GodOfAnimeStakingRewards is Ownable, ReentrancyGuard, PriceCalculator {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 multipliedAmount;   // mutiplied amount according to user's tier
        uint256 claimedReward;      // claimed reward amount user withdrawn so far
        uint256 rewardDebt;         // reward debt for calcuation of rewards earned correctly
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 rewardToken; // Address of reward token contract.
        uint256 accRewardPerShare;
        uint256 tvl;
        uint256 totalMultipliedSupply;
        uint16 withdrawFeeBP;
        uint256 claimedReward;
        uint256 prevRewardAmount;
        uint256 stakerCount;
    }

    enum Tier {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    // The Zen-Oh TOKEN!
    IERC20 public stakingToken;
    // Treasury that will provide the rewards
    address public treasury;
    // tier reward multiplier
    mapping(uint256 => uint256) public tierMutiplier;
    mapping(uint256 => uint256) public tierStartBlance;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public stakerCount;
    // The block number when GOLD mining starts.
    uint256 public startTimestamp;

    address public feeRecipient;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmissionRateUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );
    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );
    event RoundStarted(uint256 indexed id);
    event RoundEnd(uint256 indexed id);

    constructor(
        IERC20 _stakingToken,
        address _treasury,
        uint256 _startTimestamp
    ) public {
        stakingToken = _stakingToken;
        treasury = _treasury;
        startTimestamp = _startTimestamp;
        feeRecipient = msg.sender;
        tierMutiplier[uint256(Tier.BRONZE)] = 100;
        tierMutiplier[uint256(Tier.SILVER)] = 125;
        tierMutiplier[uint256(Tier.GOLD)] = 150;
        tierMutiplier[uint256(Tier.PLATINUM)] = 200;
        tierStartBlance[uint256(Tier.BRONZE)] = 0;
        tierStartBlance[uint256(Tier.SILVER)] = 10_000_000 * 1e18;
        tierStartBlance[uint256(Tier.GOLD)] = 100_000_000 * 1e18;
        tierStartBlance[uint256(Tier.PLATINUM)] = 2_000_000_000 * 1e18;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        IERC20 _rewardToken,
        uint16 _withdrawFeeBP
    ) public onlyOwner {
        require(_withdrawFeeBP < 10000, "invalid withdraw fee");
        poolInfo.push(
            PoolInfo({
                rewardToken: _rewardToken,
                accRewardPerShare: 0,
                tvl: 0,
                totalMultipliedSupply: 0,
                withdrawFeeBP: _withdrawFeeBP,
                claimedReward: 0,
                prevRewardAmount: 0,
                stakerCount: 0
            })
        );
    }

    // Update deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint16 _withdrawFeeBP
    ) public onlyOwner {
        require(_withdrawFeeBP < 10000, "invalid withdraw fee");
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date. should be called by treasury
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 rewardBalance = pool.rewardToken.balanceOf(address(this));
        if (pool.totalMultipliedSupply > 0) {
            pool.accRewardPerShare =
                pool.accRewardPerShare +
                ((rewardBalance + pool.claimedReward - pool.prevRewardAmount) *
                    1e12) /
                pool.totalMultipliedSupply;
            pool.prevRewardAmount = rewardBalance;
        }
    }

    // View function to see pending Reward token on frontend.
    function pendingReward(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        if (startTimestamp > block.timestamp) {
            return 0;
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pending = (pool.accRewardPerShare * user.multipliedAmount) /
            1e12 -
            user.claimedReward -
            user.rewardDebt;
        return pending;
    }

    function tvl(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return
            (pool.tvl *
                getTokenPriceInEthPair(
                    IUniswapV2Router02(uniswapRouter),
                    address(stakingToken)
                )) / 1e18;
    }

    function apr(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 rewardBalance = IERC20(pool.rewardToken).balanceOf(
            address(this)
        );
        if (rewardBalance > 0) {
            return
                tvl(_pid) > 0
                    ? (rewardBalance *
                        getTokenPriceInEthPair(
                            IUniswapV2Router02(uniswapRouter),
                            address(pool.rewardToken)
                        )) / tvl(_pid)
                    : 0;
        }
        return 0;
    }

    // Deposit Zen-Oh tokens
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount == 0) {
            stakerCount++;
            pool.stakerCount++;
        }
        payReward(_pid);
        if (_amount > 0) {
            uint256 userMultipliedAmountBefore = user.multipliedAmount;
            uint256 transferredAmount = deflationaryTokenTransfer(
                stakingToken,
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount + transferredAmount;
            uint256 mul = getTierMultiply(user.amount);
            user.multipliedAmount = (user.amount * mul) / 100;
            user.rewardDebt = user.multipliedAmount * pool.accRewardPerShare / 1e2;
            if (userMultipliedAmountBefore > 0) {
                pool.totalMultipliedSupply =
                    pool.totalMultipliedSupply -
                    userMultipliedAmountBefore +
                    user.multipliedAmount;
            } else {
                pool.totalMultipliedSupply =
                    pool.totalMultipliedSupply +
                    user.multipliedAmount;
            }
            pool.tvl = pool.tvl + transferredAmount;
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        payReward(_pid);
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            if (user.amount == 0) {
                stakerCount--;
                pool.stakerCount--;
            }
            uint256 mul = getTierMultiply(user.amount);
            pool.totalMultipliedSupply =
                pool.totalMultipliedSupply -
                user.multipliedAmount +
                (user.amount * mul) /
                100;
            pool.tvl = pool.tvl - _amount;
            user.multipliedAmount = (user.amount * mul) / 100;
            user.rewardDebt = user.multipliedAmount * pool.accRewardPerShare / 1e12;
            safeStakingTokenTransfer(msg.sender, _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        safeStakingTokenTransfer(msg.sender, amount);
        pool.tvl = pool.tvl - amount;
        pool.totalMultipliedSupply =
            pool.totalMultipliedSupply -
            user.multipliedAmount;
        user.multipliedAmount = 0;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending reward.
    function payReward(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = pendingReward(_pid, msg.sender);
        if (pending > 0) {
            user.claimedReward += pending;
            pool.claimedReward += pending;
            if (pool.withdrawFeeBP > 0) {
                uint256 feeAmount = (pending * pool.withdrawFeeBP) / 10000;
                safeStakingTokenTransfer(feeRecipient, feeAmount);
                pending = pending - feeAmount;
            }

            pool.rewardToken.safeTransfer(msg.sender, pending);
        }
    }

    // Safe stakingToken transfer function, just in case if rounding error causes pool to not have enough Reward tokens.
    function safeStakingTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = stakingToken.balanceOf(address(this));
        if (_amount > bal) {
            stakingToken.safeTransfer(_to, bal);
        } else {
            stakingToken.safeTransfer(_to, _amount);
        }
    }

    function getTierMultiply(uint256 amount) internal view returns (uint256) {
        uint256 multiply = 1;
        if (amount < tierStartBlance[uint256(Tier.SILVER)]) {
            multiply = tierMutiplier[uint256(Tier.BRONZE)];
        } else if (
            amount >= tierStartBlance[uint256(Tier.SILVER)] &&
            amount < tierStartBlance[uint256(Tier.GOLD)]
        ) {
            multiply = tierMutiplier[uint256(Tier.SILVER)];
        } else if (
            amount >= tierStartBlance[uint256(Tier.GOLD)] &&
            amount < tierStartBlance[uint256(Tier.PLATINUM)]
        ) {
            multiply = tierMutiplier[uint256(Tier.GOLD)];
        } else {
            multiply = tierMutiplier[uint256(Tier.PLATINUM)];
        }

        return multiply;
    }

    // Safe stakingToken transfer function, just in case if rounding error causes pool to not have enough reward token.
    function deflationaryTokenTransfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 beforeBal = _token.balanceOf(_to);
        _token.safeTransferFrom(_from, _to, _amount);
        uint256 afterBal = _token.balanceOf(_to);
        if (afterBal > beforeBal) {
            return afterBal - beforeBal;
        }
        return 0;
    }
}
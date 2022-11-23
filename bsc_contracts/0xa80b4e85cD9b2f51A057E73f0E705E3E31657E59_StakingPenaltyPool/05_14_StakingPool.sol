// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../interfaces/IStakeMaster.sol";
import "../whitelist/WhitelistUpgradeable.sol";
import "../../utils/AdminableUpgradeable.sol";

contract StakingPool is WhitelistUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool public allowReinvest;

    IERC20Upgradeable public stakingToken;
    IERC20Upgradeable public rewardToken;
    IStakeMaster public stakeMaster;

    uint256 public startTime;
    uint256 public lastRewardTime;
    uint256 public finishTime;
    uint256 public allStakedAmount;
    uint256 public allPaidReward;
    uint256 public allRewardDebt;
    uint256 public poolTokenAmount;
    uint256 public rewardPerSec;
    uint256 public accTokensPerShare; // Accumulated tokens per share
    uint256 public participants; //Count of participants

    address public feeTo; // deposit fee to this address (wihtout StakeMaster profit sharing)
    uint256 public depositFeeBP;

    uint256 public constant MAX_BPS = 10000; // 100% in basis points

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many tokens the user has staked.
        uint256 rewardDebt; // Reward debt
        bool registrated;
    }

    mapping(address => UserInfo) public userInfo;

    event PoolReplenished(uint256 amount);
    event TokensStaked(address indexed user, uint256 amount, uint256 reward, bool reinvest);
    event StakeWithdrawn(address indexed user, uint256 amount, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    event WithdrawPoolRemainder(address indexed user, uint256 amount);
    event UpdateFinishTime(uint256 addedTokenAmount, uint256 newFinishTime);
    event HasWhitelistingUpdated(bool newValue);

    event SetFeeTo(address feeTo);
    event ChargedDepositFee(uint256 feeAmountToMasterWallet, uint256 feeAmountToPoolWallet);

    event SetDepositFeeBP(uint256 depositFeeBP);

    function __StakingPool_init(
        IERC20Upgradeable _stakingToken,
        IERC20Upgradeable _poolToken,
        uint256 _startTime,
        uint256 _finishTime,
        uint256 _poolTokenAmount,
        bool _hasWhitelisting,
        IStakeMaster _stakeMaster,
        uint256 _depositFeeBP,
        address _feeTo
    ) public initializer {
        __Whitelist_init(_hasWhitelisting);
        __ReentrancyGuard_init();

        require(_startTime < _finishTime, "Start must be less than finish");
        require(_startTime > now, "Start must be more than now");
        require(_depositFeeBP <= MAX_BPS, "Invalid deposit fee BP");

        stakingToken = _stakingToken;
        rewardToken = _poolToken;
        stakeMaster = _stakeMaster;

        startTime = _startTime;
        lastRewardTime = startTime;
        finishTime = _finishTime;
        poolTokenAmount = _poolTokenAmount;
        rewardPerSec = _poolTokenAmount.div(_finishTime.sub(_startTime));

        allowReinvest = address(stakingToken) == address(rewardToken);

        feeTo = _feeTo;
        depositFeeBP = _depositFeeBP;
    }

    function getUserInfo(address user) external view returns (uint256, uint256) {
        UserInfo memory info = userInfo[user];

        return (info.amount, info.rewardDebt);
    }

    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_from >= _to) {
            return 0;
        }

        if (_to <= finishTime) {
            return _to.sub(_from);
        } else if (_from >= finishTime) {
            return 0;
        } else {
            return finishTime.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 tempAccTokensPerShare = accTokensPerShare;
        if (now > lastRewardTime && allStakedAmount != 0) {
            uint256 multiplier = getMultiplier(lastRewardTime, now);
            uint256 reward = multiplier.mul(rewardPerSec);
            tempAccTokensPerShare = accTokensPerShare.add(
                reward.mul(1e18).div(allStakedAmount)
            );
        }
        return user.amount.mul(tempAccTokensPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (now <= lastRewardTime) {
            return;
        }

        if (allStakedAmount == 0) {
            lastRewardTime = now;
            return;
        }

        uint256 multiplier = getMultiplier(lastRewardTime, now);
        uint256 reward = multiplier.mul(rewardPerSec);
        accTokensPerShare = accTokensPerShare.add(
            reward.mul(1e18).div(allStakedAmount)
        );

        lastRewardTime = now;
    }

    function reinvestTokens() external nonReentrant onlyWhitelisted {
        innerStakeTokens(0, true);
    }

    function stakeTokens(uint256 _amountToStake) public virtual nonReentrant onlyWhitelisted {
        // deposit fee logic
        uint256 feeAmount = _amountToStake.mul(depositFeeBP).div(MAX_BPS);

        chargeDepositFee(feeAmount);

        innerStakeTokens(_amountToStake.sub(feeAmount), false);
    }

    function chargeDepositFee(uint256 _feeAmount) private {
        uint256 feeAmountToMasterWallet = 0;
        uint256 feeAmountToPoolWallet = 0;

        if (_feeAmount > 0) {
            // fee to StakeMaster feeWallet address
            uint256 profitSharingBP = stakeMaster.profitSharingBP(address(this));
            if (profitSharingBP > 0) {
                feeAmountToMasterWallet = _feeAmount.mul(profitSharingBP).div(MAX_BPS);
                stakingToken.safeTransferFrom(msg.sender, stakeMaster.feeWallet(), feeAmountToMasterWallet);
            }

            // fee to feeTo address
            feeAmountToPoolWallet = _feeAmount.sub(feeAmountToMasterWallet);
            if (feeAmountToPoolWallet > 0) {
                stakingToken.safeTransferFrom(msg.sender, feeTo, feeAmountToPoolWallet);
            }
        }

        emit ChargedDepositFee(feeAmountToMasterWallet, feeAmountToPoolWallet);
    }

    function innerStakeTokens(uint256 _amountToStake, bool reinvest) private {
        updatePool();
        uint256 pending = 0;
        UserInfo storage user = userInfo[msg.sender];

        if (!user.registrated) {
            user.registrated = true;
            participants = participants.add(1);
        }

        if (user.amount > 0) {
            pending = transferPendingReward(user, reinvest);
            if (reinvest) {
                require(allowReinvest, "Reinvest disabled");
                user.amount = user.amount.add(pending);
                allStakedAmount = allStakedAmount.add(pending);
            }
        }

        if (_amountToStake > 0) {
            uint256 balanceBefore = stakingToken.balanceOf(address(this));
            stakingToken.safeTransferFrom(msg.sender, address(this), _amountToStake);
            uint256 received = stakingToken.balanceOf(address(this)).sub(balanceBefore);
            _amountToStake = received;
            user.amount = user.amount.add(_amountToStake);
            allStakedAmount = allStakedAmount.add(_amountToStake);
        }

        allRewardDebt = allRewardDebt.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(accTokensPerShare).div(1e18);
        allRewardDebt = allRewardDebt.add(user.rewardDebt);

        emit TokensStaked(msg.sender, _amountToStake, pending, reinvest);
    }

    // Leave the pool. Claim back your tokens.
    // Unlocks the staked + gained tokens and burns pool shares
    function withdrawStake(uint256 _amount) public virtual nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        updatePool();

        uint256 pending = transferPendingReward(user, false);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakingToken.safeTransfer(msg.sender, _amount);
        }

        allRewardDebt = allRewardDebt.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(accTokensPerShare).div(1e18);
        allRewardDebt = allRewardDebt.add(user.rewardDebt);
        allStakedAmount = allStakedAmount.sub(_amount);

        emit StakeWithdrawn(msg.sender, _amount, pending);
    }

    function transferPendingReward(UserInfo memory user, bool reinvest) internal returns (uint256) {
        uint256 pending = user.amount.mul(accTokensPerShare).div(1e18).sub(user.rewardDebt);

        if (pending > 0) {
            if (!reinvest) {
                rewardToken.safeTransfer(msg.sender, pending);
            }
            allPaidReward = allPaidReward.add(pending);
        }

        return pending;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public virtual nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            stakingToken.safeTransfer(msg.sender, user.amount);

            emit EmergencyWithdraw(msg.sender, user.amount);

            allStakedAmount = allStakedAmount.sub(user.amount);
            allRewardDebt = allRewardDebt.sub(user.rewardDebt);
            user.amount = 0;
            user.rewardDebt = 0;
        }
    }

    function withdrawPoolRemainder() external onlyOwner nonReentrant {
        require(now > finishTime, "Allow after finish");

        updatePool();

        uint256 pending = allStakedAmount.mul(accTokensPerShare).div(1e18).sub(allRewardDebt);
        uint256 returnAmount = poolTokenAmount.sub(allPaidReward).sub(pending);
        allPaidReward = allPaidReward.add(returnAmount);

        rewardToken.safeTransfer(msg.sender, returnAmount);

        emit WithdrawPoolRemainder(msg.sender, returnAmount);
    }

    function extendDuration(uint256 _addTokenAmount) external onlyOwnerOrAdmin nonReentrant {
        rewardToken.safeTransferFrom(msg.sender, address(this), _addTokenAmount);
        poolTokenAmount = poolTokenAmount.add(_addTokenAmount);
        finishTime = finishTime.add(_addTokenAmount.div(rewardPerSec));

        emit UpdateFinishTime(_addTokenAmount, finishTime);
    }

    function setHasWhitelisting(bool value) external onlyOwnerOrAdmin {
        hasWhitelisting = value;

        emit HasWhitelistingUpdated(hasWhitelisting);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;

        emit SetFeeTo(_feeTo);
    }

    function setDepositFeeBP(uint256 _depositFeeBP) external onlyOwnerOrAdmin {
        require(_depositFeeBP <= stakeMaster.maxDepositFee(), "setDepositFee: _depositFeeBP cannot be more maxDepositFee");

        depositFeeBP = _depositFeeBP;

        emit SetDepositFeeBP(_depositFeeBP);
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 1015; // 1.0.1.5
    }
}
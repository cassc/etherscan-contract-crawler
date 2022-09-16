// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/other/divestor_upgradeable.sol";
import "contracts/interface/IPancake.sol";

// import "hardhat/console.sol";

interface IBEP20 is IERC20, IERC20Metadata {

}

contract BVStake is OwnableUpgradeable, DivestorUpgradeable {
    struct Meta {
        bool isOpen;
        address banker;
        address wallet;
        IBEP20 stakeToken;
        IBEP20 rewardToken;
        IPancakePair stakePair;
        IPancakePair rewardPair;
        address usdt;
        address wbnb;
        IPancakePair bnbPair;
    }
    struct Slot {
        uint256 lockTime;
        uint256 rate;
        uint256 stakeAmount;
    }
    struct Pool {
        uint256 rate;
        uint256 lastTime;
        uint256 stakeTime;
        uint256 endTime;
        uint256 debted;
        uint256 endDebted;
        uint256 tvl;
    }
    struct UserSlot {
        uint256 debted;
        uint256 lastStakeTime;
        uint256 stakeAmount;
    }
    struct User {
        address inviter;
        uint256 referReward;
        uint256 referRewarded;
        uint256 claimed;
        uint256 toClaim;
        UserSlot[3] slots;
    }
    struct Debt {
        uint256 debted;
        uint256 tm;
        uint256 tvl;
    }

    uint256 constant ACC = 1e22;
    Meta public meta;
    Pool public pool;
    Slot[3] public soltInfo;
    mapping(address => User) public userInfo;

    uint256 public lastIndex;
    mapping(uint256 => Debt) public secDebt;

    uint8 public refLevel;
    uint8 public refTotalRate;
    mapping(uint8 => uint8) public refRate;

    modifier check(uint256 poolId_) {
        require(poolId_ >= 0 && poolId_ < 4, "wrong cycle");
        require(msg.sender == tx.origin, "ban");
        Pool memory pInfo = pool;
        if (pInfo.endTime != 0 && pInfo.endDebted != 0 && block.timestamp >= pInfo.endTime) {
            pool.endDebted = pInfo.tvl > 0 ? (pInfo.rate * (pool.endTime - pInfo.lastTime) * ACC) / pInfo.tvl + pInfo.debted : 0 + pInfo.debted;
        }
        _;
    }

    event Stake(address indexed account, uint256 indexed slotId, uint256 indexed amountm);
    event UnStake(address indexed account, uint256 indexed slotId, uint256 indexed amount);
    event ClaimReward(address indexed account, uint256 indexed reward);
    event ClaimReferReward(address account, uint256 reward);

    function initialize() public initializer {
        __Ownable_init_unchained();

        meta.usdt = 0x55d398326f99059fF775485246999027B3197955;
        meta.wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        meta.bnbPair = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
        meta.stakePair = IPancakePair(0x4694bc7b08ccf8BE8057608421893b023e0FFF66);
        meta.rewardPair = IPancakePair(0x11c0b2BB4fbB430825d07507A9E24e4c32f7704D);

        meta.stakeToken = IBEP20(0x1DaCbcD9B3fc2d6A341Dca3634439D12bC71cA4d);
        meta.rewardToken = IBEP20(0x77d547256A2cD95F32F67aE0313E450Ac200648d);

        meta.banker = 0x9944204Dc488e1d8C3d9052b34fAaF39C300BA1C;
        meta.wallet = 0x8335E209F13A9326EC6F17d694244Cf3cb779314;

        meta.isOpen = true;

        setSlots(0, 0, 10);
        setSlots(1, 3 days, 13);
        setSlots(2, 7 days, 20);

        pool.stakeTime = 1663329600;
        pool.endTime = 1663329600 + 15 days; // 1664625600
        pool.rate = uint256(2544 ether) / 15 days;

        refLevel = 2;
        refTotalRate = 30;
        refRate[0] = 20;
        refRate[1] = 10;
    }

    function stake(
        uint256 slotId_,
        uint256 stakeAmount_,
        address inviter_
    ) public check(slotId_) {
        Slot storage sInfo = soltInfo[slotId_];
        User storage uInfo = userInfo[msg.sender];
        require(pool.stakeTime != 0 && block.timestamp >= pool.stakeTime, "Coming soon");
        require(block.timestamp + sInfo.lockTime <= pool.endTime, "This staking period has ended");

        if (uInfo.inviter == address(0) && inviter_ != address(0)) {
            require(verifyInviter(msg.sender, inviter_), "Invalid referral address");
            uInfo.inviter = inviter_;
        }

        (uint256 toClaim, ) = viewRewardWithSlot(msg.sender, slotId_);
        uint256 newDebt = coutingDebt();
        if (toClaim > 0) {
            uInfo.toClaim += toClaim;
        }

        sInfo.stakeAmount += stakeAmount_;
        uint256 stakeValue = (stakeAmount_ * sInfo.rate) / 10;

        _updateUserAndPool(slotId_, stakeAmount_, stakeValue, newDebt, true);

        meta.stakeToken.transferFrom(msg.sender, address(this), stakeAmount_);
        emit Stake(msg.sender, slotId_, stakeAmount_);
    }

    function unStake(uint256 slotId_) public check(slotId_) {
        User storage uInfo = userInfo[msg.sender];
        Slot storage sInfo = soltInfo[slotId_];
        require(uInfo.slots[slotId_].stakeAmount > 0, "You don't have any staked BVT");
        require(block.timestamp >= uInfo.slots[slotId_].lastStakeTime + sInfo.lockTime, "not release");

        uint256 newDebt = coutingDebt();
        (uint256 toClaim, ) = viewRewardWithSlot(msg.sender, slotId_);
        uInfo.toClaim += toClaim;

        uint256 stakeAmount = uInfo.slots[slotId_].stakeAmount;
        uint256 stakeValue = (stakeAmount * sInfo.rate) / 10;

        sInfo.stakeAmount -= stakeAmount;

        _updateUserAndPool(slotId_, stakeAmount, stakeValue, newDebt, false);

        meta.stakeToken.transfer(msg.sender, stakeAmount);
        emit UnStake(msg.sender, slotId_, stakeAmount);
    }

    function claimReward() public check(0) {
        (uint256 stakeReward, uint256 refReward, , uint256[3] memory nedDebteds) = viewRewards(msg.sender);
        require(stakeReward > 0 || refReward > 0, "not reward");

        if (refReward > 0) {
            _claimReferReward(msg.sender, refReward);
        }

        if (stakeReward == 0) return;

        uint256 invReward = (stakeReward * refTotalRate) / 100;
        uint256 reward = stakeReward - invReward;

        _takeInviterReward(stakeReward, invReward);

        User storage uInfo = userInfo[msg.sender];
        for (uint256 i; i < 3; i++) {
            if (nedDebteds[i] > 0) {
                uInfo.slots[i].debted = nedDebteds[i];
            }
        }
        uInfo.toClaim = 0;
        uInfo.claimed += reward;

        meta.rewardToken.transferFrom(meta.wallet, msg.sender, reward);
        emit ClaimReward(msg.sender, reward);
    }

    function viewRewards(address account_)
        public
        view
        returns (
            uint256 stakeReawrd,
            uint256 refReward,
            uint256[3] memory rewards,
            uint256[3] memory nedDebteds
        )
    {
        refReward = userInfo[account_].referReward - userInfo[account_].referRewarded;
        stakeReawrd = userInfo[account_].toClaim;
        for (uint256 i; i < 3; i++) {
            (rewards[i], nedDebteds[i]) = viewRewardWithSlot(account_, i);
            stakeReawrd += rewards[i];
        }
    }

    function viewRewardWithSlot(address account_, uint256 slotId_) public view returns (uint256 reward, uint256 newDebted) {
        Slot memory sInfo = soltInfo[slotId_];
        UserSlot memory uInfo = userInfo[account_].slots[slotId_];

        if (uInfo.stakeAmount == 0) {
            return (0, 0);
        }

        uint256 endTime = uInfo.lastStakeTime + sInfo.lockTime;
        newDebted = slotId_ == 0 || uInfo.lastStakeTime == 0 ? coutingDebt() : coutingDebtWithTm(endTime);

        uint256 stakeValue = (uInfo.stakeAmount * sInfo.rate) / 10;
        reward = ((newDebted - uInfo.debted) * stakeValue) / (ACC * 1e10);
    }

    function binarySearch(uint256 tm_) public view returns (uint256) {
        uint256 left;
        uint256 right = lastIndex;
        if (lastIndex == 0 || tm_ >= secDebt[right].tm) {
            return right;
        }
        while (right - left > 1) {
            uint256 mid = (left + right) / 2;
            if (tm_ == secDebt[mid].tm) {
                return mid;
            } else if (tm_ > secDebt[mid].tm) {
                left = mid;
            } else if (tm_ < secDebt[mid].tm) {
                right = mid;
            } else {
                return 0;
            }
        }
        return left;
    }

    function coutingDebt() public view returns (uint256) {
        Pool memory pInfo = pool;
        if (pInfo.endDebted != 0) {
            return pInfo.endDebted;
        }

        uint256 tm = block.timestamp > pInfo.endTime ? pInfo.endTime : block.timestamp;
        uint256 newDebt = pInfo.tvl > 0 ? (pInfo.rate * (tm - pInfo.lastTime) * ACC) / pInfo.tvl + pInfo.debted : 0 + pInfo.debted;
        return newDebt;
    }

    function coutingDebtWithTm(uint256 tm_) public view returns (uint256) {
        if (tm_ >= block.timestamp || pool.endDebted != 0) {
            return coutingDebt();
        }

        uint256 index = binarySearch(tm_);
        if (tm_ == secDebt[index].tm) {
            return secDebt[index].debted;
        }

        uint256 endTm = tm_ > pool.endTime ? pool.endTime : tm_;
        uint256 newDebt = secDebt[index].tvl > 0 ? (pool.rate * (endTm - secDebt[index].tm) * ACC) / secDebt[index].tvl : 0;
        newDebt += secDebt[index].debted;
        return newDebt;
    }

    function getBNBPrice() public view returns (uint256 price) {
        (uint256 re0, uint256 re1, ) = meta.bnbPair.getReserves();
        price = meta.bnbPair.token0() == meta.wbnb ? (re1 * 1e18) / re0 : (re0 * 1e18) / re1;
    }

    function getRewardTokenRrice() public view returns (uint256 price) {
        uint256 bnbPrice = getBNBPrice();
        (uint256 re0, uint256 re1, ) = meta.rewardPair.getReserves();
        uint256 decimal = 10**(18 - meta.rewardToken.decimals());
        price = meta.rewardPair.token0() == meta.wbnb ? (re0 * bnbPrice) / (re1 * decimal) : (re1 * bnbPrice) / (re0 * decimal);
    }

    function getStakeTokenRrice() public view returns (uint256 price) {
        (uint256 re0, uint256 re1, ) = meta.stakePair.getReserves();
        price = meta.stakePair.token0() == meta.usdt ? (re0 * 1e18) / re1 : (re1 * 1e18) / re0;
    }

    function getDiffDecmials() public view returns (uint256) {
        uint256 sDecimal = meta.stakeToken.decimals();
        uint256 rDecimal = meta.rewardToken.decimals();

        return sDecimal > rDecimal ? 10**(sDecimal - rDecimal) : 10**(rDecimal - sDecimal);
    }

    function _takeInviterReward(uint256 totalReward_, uint256 refReward_) private {
        uint256 allowReward;
        address inviter = msg.sender;
        for (uint8 i; i < refLevel; i++) {
            inviter = userInfo[inviter].inviter;
            if (inviter == address(0)) {
                break;
            }
            uint256 reward = (totalReward_ * refRate[i]) / 100;
            userInfo[inviter].referReward += reward;
            allowReward += reward;
        }

        if (refReward_ > allowReward) {
            meta.rewardToken.transferFrom(meta.wallet, meta.banker, refReward_ - allowReward);
        }
    }

    function _updateUserAndPool(
        uint256 slotId_,
        uint256 stakeAmount_,
        uint256 stakeValue_,
        uint256 newDebted_,
        bool isAdd_
    ) private {
        UserSlot storage uInfo = userInfo[msg.sender].slots[slotId_];
        if (isAdd_) {
            pool.tvl += stakeValue_;
            uInfo.stakeAmount += stakeAmount_;
            uInfo.lastStakeTime = block.timestamp;
        } else {
            pool.tvl -= stakeValue_;
            uInfo.stakeAmount = 0;
            uInfo.lastStakeTime = 0;
        }

        lastIndex++;
        secDebt[lastIndex] = Debt({ debted: newDebted_, tm: block.timestamp, tvl: pool.tvl });

        pool.debted = newDebted_;
        pool.lastTime = block.timestamp;

        uInfo.debted = uInfo.stakeAmount > 0 ? newDebted_ : 0;
    }

    function _claimReferReward(address account_, uint256 reward_) private {
        userInfo[account_].referRewarded = userInfo[account_].referReward;
        meta.rewardToken.transferFrom(meta.wallet, account_, reward_);

        emit ClaimReferReward(account_, reward_);
    }

    function verifyInviter(address account_, address inviter_) public view returns (bool) {
        if (inviter_ == account_) {
            return false;
        }
        if (userInfo[inviter_].inviter == account_) {
            return false;
        }

        for (uint256 i; i < 3; i++) {
            if (userInfo[inviter_].slots[i].stakeAmount > 0) {
                return true;
            }
        }

        return false;
    }

    function viewInfo(address account_)
        public
        view
        returns (
            address inviter,
            uint256[7] memory info,
            uint256[3] memory apys,
            uint256[3][3] memory poolInfo,
            uint256[2][3] memory uPoolInfo
        )
    {
        inviter = userInfo[account_].inviter;
        info[0] = pool.stakeTime;
        info[1] = pool.endTime;

        (info[3], info[4], , ) = viewRewards(account_);
        info[5] = userInfo[account_].claimed;
        info[6] = userInfo[account_].referRewarded;

        apys = coutingApy();

        User memory uInfo = userInfo[account_];
        for (uint256 i; i < 3; i++) {
            uint256 lockTime = soltInfo[i].lockTime;
            poolInfo[i] = [lockTime, soltInfo[i].rate, soltInfo[i].stakeAmount];

            uint256 userStake = uInfo.slots[i].stakeAmount;
            uint256 lastStakeTime = uInfo.slots[i].lastStakeTime;
            uPoolInfo[i] = [userStake, lastStakeTime > 0 ? lastStakeTime + lockTime : 0];
            info[2] += userStake;
        }
    }

    function coutingApy() public view returns (uint256[3] memory apys) {
        uint256 rPrice = getRewardTokenRrice();
        uint256 sPrice = getStakeTokenRrice();
        for (uint256 i; i < 3; i++) {
            uint256 stakeAmount = (soltInfo[i].stakeAmount * soltInfo[i].rate) / 10;
            if (stakeAmount == 0) continue;
            uint256 reward = ((2544 ether / 15) * stakeAmount) / pool.tvl;
            apys[i] = (reward * rPrice * 365 * 1e5) / (soltInfo[i].stakeAmount * sPrice);
        }
    }

    function userSlot(address account_, uint256 slotId_) public view returns (UserSlot memory sInfo) {
        return userInfo[account_].slots[slotId_];
    }

    function setSlots(
        uint256 index_,
        uint256 lockTime_,
        uint256 rate_
    ) private {
        soltInfo[index_].lockTime = lockTime_;
        soltInfo[index_].rate = rate_;
    }
}
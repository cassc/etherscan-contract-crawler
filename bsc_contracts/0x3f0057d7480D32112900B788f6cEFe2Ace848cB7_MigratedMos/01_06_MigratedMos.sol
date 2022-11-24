//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract MigratedMos is ERC20, Ownable{
    uint256 public constant maxSupply = 136000000000 * 10 ** 18;

    /* Time of contract launch (Wednesday, August 25, 2021 12:00:00 PM UTC) */
    uint256 internal immutable LAUNCH_TIME;

    uint256 internal constant MIN_STAKE_DAYS = 10;
    uint256 internal constant MAX_STAKE_DAYS = 6666;

    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = 2 * 7;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = 100 * 7;

    uint256 internal constant LPB = 364 * 100 / 20;
    uint256 internal constant LPB_MAX_DAYS = LPB * 200 / 100;

    uint256 internal constant BPB_MAX_HEARTS = 80 * 1e6 * 10 ** 18;
    uint256 internal constant BPB = BPB_MAX_HEARTS * 100 / 10;
    
    uint256 internal claimed = 2;


    struct GlobalsStore {
        uint256 lockedHeartsTotal;
        uint256 latestStakeId;
    }

    struct StakeCache {
        uint256 _stakeId;
        uint256 _stakedHearts;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;
    }

    struct StakeStore {
        uint256 stakeId;
        uint256 stakedHearts;
        uint256 lockedDay;
        uint256 stakedDays;
        uint256 unlockedDay;
    }

    GlobalsStore public globals;
    mapping(address => StakeStore[]) public stakeLists;

    constructor() ERC20 ("MOS Token","MOS") {
        LAUNCH_TIME = block.timestamp;
    }

    event StakeStart(uint256 amount, uint256 stakeDays, address indexed stakerAddr, uint256 stakeId, uint256 stakeOnDay);
    event StakeEnd(uint256 payout, address indexed stakerAddr, uint256 stakeId, uint256 endDay);

    function currentDay() public view returns (uint256) {   
        return (block.timestamp - LAUNCH_TIME) / 1 days + 1;
    }

    function stakeStart(uint256 amtToStake, uint256 dayToStake) external {
        require(amtToStake > 0, "MOS: Invalid staking amount");
        require(dayToStake >= MIN_STAKE_DAYS, "MOS: Staking day lower than minimum");
        require(dayToStake <= MAX_STAKE_DAYS, "MOS: Staking day higher than maximum");

        uint256 bonusHearts = _stakeStartBonusHearts(amtToStake, dayToStake);
        uint256 totalStakes = amtToStake + bonusHearts;
        uint256 newLockedDay = currentDay() < 1 ? 1 + 1: currentDay() + 1;
        uint256 newStakeId = ++globals.latestStakeId;
        _stakeAdd(stakeLists[msg.sender], newStakeId, amtToStake, newLockedDay, dayToStake);
        emit StakeStart(amtToStake, dayToStake, msg.sender, newStakeId, newLockedDay);
        globals.lockedHeartsTotal += totalStakes;
        _burn(msg.sender, amtToStake);
    }

    function _stakeStartBonusHearts(uint256 amtToStake, uint256 dayToStake) internal pure returns (uint256 bonusHearts) {
        uint256 cappedExtraDays = 0;
        if (dayToStake > 1) {
            cappedExtraDays = dayToStake <= LPB_MAX_DAYS ? dayToStake - 1 : LPB_MAX_DAYS;
        }
        uint256 cappedStakedHearts = amtToStake <= BPB_MAX_HEARTS ? amtToStake : BPB_MAX_HEARTS;
        uint256 bonus = cappedExtraDays * BPB + cappedStakedHearts * LPB;
        bonusHearts = amtToStake * bonus / (LPB * BPB);
        return bonusHearts;
    }

    function _stakeAdd(StakeStore[] storage stakeListRef, uint256 newStakeId, uint256 newStakedHearts, uint256 newLockedDay, uint256 newStakedDays) internal {
        stakeListRef.push(StakeStore(newStakeId, uint256(newStakedHearts), uint256(newLockedDay), uint256(newStakedDays),uint256(0)));
    }

    function stakeEnd(uint256 stakeIndex, uint256 stakeIdParam) external {
        StakeStore[] storage slr = stakeLists[msg.sender];

        /* require() is more informative than the default assert() */
        require(slr.length != 0, "MOS: Empty stake list");
        require(stakeIndex < slr.length, "MOS: stakeIndex invalid");

        StakeCache memory st;
        _stakeLoad(slr[stakeIndex], stakeIdParam, st);
        uint256 servedDays = 0;
        bool prevUnlocked = (st._unlockedDay != 0);
        uint256 stakeReturn;
        uint256 payout = 0;
        uint256 penalty = 0;
        uint256 cappedPenalty = 0;

        if (currentDay() >= st._lockedDay) {
            if (prevUnlocked) {
                servedDays = st._stakedDays;
            } else {
                st._unlockedDay = currentDay();
                servedDays = currentDay() - st._lockedDay;
                if (servedDays > st._stakedDays) {
                    servedDays = st._stakedDays;
                }
            }
            (stakeReturn, payout, penalty, cappedPenalty) = _stakePerformance(st, servedDays);
        } else {
            stakeReturn = st._stakedHearts;
        }

        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);
        }
        emit StakeEnd(stakeReturn, msg.sender, stakeIdParam, currentDay());
        globals.lockedHeartsTotal -= st._stakedHearts;
        _stakeRemove(slr, stakeIndex);
    }

    function _stakeLoad(StakeStore storage stRef, uint256 stakeIdParam, StakeCache memory st) internal view {
        require(stakeIdParam == stRef.stakeId, "MOS: stakeIdParam not in stake");

        st._stakeId = stRef.stakeId;
        st._stakedHearts = stRef.stakedHearts;
        st._lockedDay = stRef.lockedDay;
        st._stakedDays = stRef.stakedDays;
        st._unlockedDay = stRef.unlockedDay;
    }

    function _stakePerformance(StakeCache memory st, uint256 servedDays) internal view returns (uint256 stakeReturn, uint256 payout, uint256 penalty, uint256 cappedPenalty) {
        if (servedDays < st._stakedDays) {
            (payout, penalty) = _calcPayoutAndEarlyPenalty(
                st._stakedDays,
                servedDays,
                st._stakedHearts
            );
            stakeReturn = st._stakedHearts + payout;
        } else {
            payout = (st._stakedHearts * st._stakedDays * 20 / 2920 / 100) + (st._stakedHearts * st._stakedHearts * 10 / 80000000e18 / 100) * 78 / 1000;
            stakeReturn = st._stakedHearts + payout;

            penalty = _calcLatePenalty(st._lockedDay, st._stakedDays, st._unlockedDay, stakeReturn);
        }
        if (penalty != 0) {
            if (penalty > stakeReturn) {
                cappedPenalty = stakeReturn;
                stakeReturn = 0;
            } else {
                cappedPenalty = penalty;
                stakeReturn -= cappedPenalty;
            }
        }
        return (stakeReturn, payout, penalty, cappedPenalty);
    }

    function _calcPayoutAndEarlyPenalty(uint256 stakedDaysParam, uint256 servedDays, uint256 stakeAmt ) internal view returns (uint256 payout, uint256 penalty){
        uint256 penaltyDays = (stakedDaysParam + 1) / 2;
        if (penaltyDays < EARLY_PENALTY_MIN_DAYS) {
            penaltyDays = EARLY_PENALTY_MIN_DAYS;
        }

        if (servedDays == 0) {
            uint256 expected = _estimatePayoutRewardsDay(stakeAmt);
            penalty = expected * penaltyDays;
            return (payout, penalty); // Actual payout was 0
        }

        payout = (stakeAmt * stakedDaysParam * 20 / 2920 / 100) + (stakeAmt * stakeAmt * 10 / 80000000e18 / 100) * 78 / 1000;

        if (penaltyDays > servedDays) {
            penalty = (stakeAmt * servedDays * 20 / 2920 / 100) + (stakeAmt * stakeAmt * 10 / 80000000e18 / 100) * 78 / 1000;
            payout = (stakeAmt * stakedDaysParam * 20 / 2920 / 100) + (stakeAmt * stakeAmt * 10 / 80000000e18 / 100) * 78 / 1000;
            return (payout, penalty);
        }
        return (payout, penalty);
    }

    function _estimatePayoutRewardsDay(uint256 stakeAmt) internal view returns (uint256 payout) {
        /*
        Calculate payout round

        Inflation of 7.80% inflation per 364 days (approx 1 year)
        dailyInterestRate   = 7.8% / 364
                            = 0.078 / 364
                            = 0.00021428571428571427 (approx)

        payout  = allocSupply * dailyInterestRate
                = allocSupply / (1 / dailyInterestRate)
                = allocSupply / (1 / 0.00021428571428571427)
                = allocSupply / 4692.307692307692(approx)
                = allocSupply * 10000 / 46923076 (* 10000/10000 for int precision)
        */
        payout = totalSupply() + globals.lockedHeartsTotal * stakeAmt / 46666666;
        return payout;
    }

    function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex) internal {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }
        /*
            Reduce the array length now that the array is contiguous.
            Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
        */
        stakeListRef.pop();
    }

    function migrateMint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

    function stakeCount(address stakerAddr) external view returns (uint256) {
        return stakeLists[stakerAddr].length;
    }

    function _calcLatePenalty(uint256 lockedDayParam, uint256 stakedDaysParam, uint256 unlockedDayParam, uint256 rawStakeReturn) private pure returns (uint256) {
        /* Allow grace time before penalties accrue */
        uint256 maxUnlockedDay = lockedDayParam + stakedDaysParam + LATE_PENALTY_GRACE_DAYS;
        if (unlockedDayParam <= maxUnlockedDay) {
            return 0;
        }

        /* Calculate penalty as a percentage of stake return based on time */
        return rawStakeReturn * (unlockedDayParam - maxUnlockedDay) / LATE_PENALTY_SCALE_DAYS;
    }
}
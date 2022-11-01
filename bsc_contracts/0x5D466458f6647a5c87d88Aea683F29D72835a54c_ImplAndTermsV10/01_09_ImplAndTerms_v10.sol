// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20Init.sol";
import "../Storage.sol";
import "../utils/DoTransfer.sol";

contract ImplAndTermsV10 is Storage, Ownable, DoTransfer, ERC20Init {
    address public manager;
    address public stakeToken;

    bool public stakeIsPaused;
    bool public unstakeIsPaused;

    uint public refererBonusPercent;
    uint public influencerBonusPercent;
    uint public developerBonusPercent;
    uint public timeBonusPercent;

    uint public timeNormalizer;
    uint public unHoldFee;
    uint public holdTimeRefMin;
    uint public holdTimeMax;

    // for inflation
    uint public inflationPercent;
    address public reservoir;
    uint public totalStaked;
    uint public accrualBlockTimestamp;
    uint public inflationRatePerSec;

    struct StakeData {
        uint stakeAmount;
        uint lpAmount;
        uint stakeTime;
        uint holdTime;
        bool active; // true is active
        uint closeRate;
        uint closeTime;
        uint closeAmount;
    }

    mapping(address => StakeData[]) public userStakes;
    mapping(uint => uint) public bonusTime; // for manager

    uint public maxDefaultApprovedReward;

    // user => stakeId => bool
    mapping(address => mapping(uint => bool)) public approvedRewards;
    mapping(address => mapping(uint => bool)) public sentRewards;

    event Stake(address indexed staker, uint userStakeId, uint stakeAmount, uint holdTime, uint lpAmountOut);
    event Unstake(address indexed staker, uint userStakeId, uint stakeTokenAmountOut, uint rate);

    event AccrueInterest(uint interestAccumulated, uint totalStaked);

    event ApproveRequest(address user, uint stakeId);

    function initialize(
        address ,
        address stakeToken_,
        address reservoir_,
        string memory name_,
        string memory symbol_
    ) public {
        require(stakeToken == address(0), "ImplAndTerms::initialize: may only be initialized once");

        require(
            stakeToken_ != address(0)
            && reservoir_ != address(0),
            "ImplAndTerms::initialize: address is 0"
        );

        stakeToken = stakeToken_;

        refererBonusPercent = 10e18; // 10%
        timeBonusPercent = 20e18; // 20%
        unHoldFee = 100e18; // 100%
        inflationPercent = 400e18; // 400%

        holdTimeRefMin = 1 days;
        holdTimeMax = 365 days;
        timeNormalizer = 365 days;

        bonusTime[30 days] = 5e18;
        bonusTime[90 days] = 20e18;
        bonusTime[180 days] = 40e18;

        reservoir = reservoir_;
        accrualBlockTimestamp = getBlockTimestamp();
        inflationRatePerSec = inflationPercent / 365 days;

        super.initialize(name_, symbol_);
    }

    function _setPause(bool stakeIsPaused_, bool unstakeIsPaused_) public onlyOwner returns (bool) {
        stakeIsPaused = stakeIsPaused_;
        unstakeIsPaused = unstakeIsPaused_;

        return true;
    }

    function _setManager(address manager_) public onlyOwner returns (bool) {
        manager = manager_;

        return true;
    }

    // transfer stake tokens from user to pool
    // mint lp tokens from pool to user
    function stake(uint tokenAmount) public {
        stakeInternal(msg.sender, tokenAmount, 0, address(0), address(0), false);
    }

    function stake(uint tokenAmount, uint holdTime) public {
        stakeInternal(msg.sender, tokenAmount, holdTime, address(0), address(0), false);
    }

    function stake(uint tokenAmount, uint holdTime, address referer) public {
        stakeInternal(msg.sender, tokenAmount, holdTime, referer, address(0), false);
    }

    // mint lp tokens from pool to beneficiary
    function stake(uint tokenAmount, uint holdTime, address referer, address beneficiary) public {
        if (msg.sender == manager) {
            stakeInternal(msg.sender, tokenAmount, holdTime, address(0), beneficiary, true);
        } else {
            stakeInternal(msg.sender, tokenAmount, holdTime, referer, beneficiary, false);
        }
    }

    function stakeInternal(address staker, uint tokenAmount, uint holdTime, address referer, address beneficiary, bool harvest) internal {
        require(!stakeIsPaused, 'ImplAndTerms::stakeInternal: stake is paused');

        require(
            referer != staker,
            "ImplAndTerms::stakeInternal: referer address must not match staker address"
        );
        require(holdTime <= holdTimeMax, "ImplAndTerms::stakeInternal: hold time must be less than holdTimeMax");

        accrueInterest();

        uint amountIn = doTransferIn(staker, stakeToken, tokenAmount);

        if (holdTime > 0) {
            holdTime = holdTime - holdTime % 86400;
        }

        if (harvest) {
            require(
                beneficiary != address(0),
                "ImplAndTerms::stakeInternal: beneficiary address is 0"
            );

            stakeFresh(beneficiary, amountIn, holdTime);
        } else if (beneficiary != address(0)) {
            stakeFresh(beneficiary, amountIn, holdTime);
        } else {
            stakeFresh(staker, amountIn, holdTime);
        }

        totalStaked += amountIn;
    }

    function stakeFresh(address staker, uint stakeAmount, uint holdTime) internal {
        _mint(staker, 1);

        userStakes[staker].push(
            StakeData({
                stakeAmount: stakeAmount,
                lpAmount: 1,
                stakeTime: block.timestamp,
                holdTime: holdTime,
                active: true,
                closeRate: 0,
                closeTime: 0,
                closeAmount: 0
            })
        );

        emit Stake(staker, userStakes[staker].length, stakeAmount, holdTime, 1);
    }

    function calcAllLPAmountOut(uint amountIn, uint holdTime, uint rate, bool harvest) public view returns (uint, uint, uint) {
        uint stakerLpAmountOut = calcStakerLPAmount(amountIn, holdTime, rate, harvest);
        uint refererLpAmountOut = calcRefererLPAmount(amountIn);
        uint totalAmount = stakerLpAmountOut + refererLpAmountOut;

        return (totalAmount, stakerLpAmountOut, refererLpAmountOut);
    }

    function calcStakerLPAmount(uint amountIn, uint holdTime, uint, bool) public view returns (uint) {
        return amountIn + calcBonusTime(amountIn, holdTime, false);
    }

    function calcBonusTime(uint amount, uint holdTime, bool) public view returns (uint) {
        return amount * holdTime * timeBonusPercent / 100e18 / timeNormalizer;
    }

    function calcRefererLPAmount(uint amount) public view returns (uint) {
        return amount * refererBonusPercent / 100e18;
    }

    // rate scaled by 1e18
    function getRate() public pure returns (uint) {
        return 1e18;
    }

    function _approveRewards(address user, uint[] calldata stakeIds) public onlyOwner returns (bool) {
        for (uint i = 0; i < stakeIds.length; i++) {
            approvedRewards[user][stakeIds[i]] = true;
        }

        return true;
    }

    function getApprovedUnstake(uint stakeId) public returns (bool) {
        require(approvedRewards[msg.sender][stakeId], "ImplAndTerms::unstake: unstake reward is not approved");
        require(!sentRewards[msg.sender][stakeId], "ImplAndTerms::unstake: unstake reward is sent");

        bool active;
        uint closeAmount;

        (,,,, active,,,closeAmount) = getUserStake(msg.sender, stakeId);

        require(!active, "ImplAndTerms::unstake: stake is active");
        require(closeAmount > 0, "ImplAndTerms::unstake: close amount is 0");

        approvedRewards[msg.sender][stakeId] = false;
        sentRewards[msg.sender][stakeId] = true;

        doTransferOut(stakeToken, msg.sender, closeAmount);

        return true;
    }

    function _setMinApprovedReward(uint maxDefaultApprovedReward_) public onlyOwner returns (bool) {
        maxDefaultApprovedReward = maxDefaultApprovedReward_;

        return true;
    }

    // burn lp tokens from user
    // transfer stake tokens from pool to user
    function unstake(uint[] calldata userStakeIds) external {
        require(!unstakeIsPaused, 'ImplAndTerms::unstake: unstake is paused');

        accrueInterest();

        uint allLpAmountOut;
        uint stakeTokenAmountOut;
        uint lpAmountOut;
        uint stakeTime;
        uint holdTime;
        bool active;
        uint amountOut;
        uint notApprovedStakeTokenAmountOut;
        uint stakeAmount;
        uint timeBonus;
        uint totalTimeBonus;

        for (uint i = 0; i < userStakeIds.length; i++) {
            require(userStakeIds[i] < userStakes[msg.sender].length, "ImplAndTerms::unstake: stake is not exist");

            (stakeAmount, lpAmountOut, stakeTime, holdTime, active,,,) = getUserStake(msg.sender, userStakeIds[i]);

            require(active, "ImplAndTerms::unstake: stake is not active");

            allLpAmountOut += lpAmountOut;
            amountOut = stakeAmount;
            amountOut += inflationRatePerSec * (block.timestamp - stakeTime) * stakeAmount / 100e18;

            stakeTokenAmountOut += amountOut;

            if (holdTime > (block.timestamp - stakeTime)) {
                timeBonus = calcBonusTime(stakeAmount, (block.timestamp - stakeTime), false);
            } else {
                timeBonus = calcBonusTime(stakeAmount, holdTime, false);
            }
            doTransferIn(reservoir, stakeToken, timeBonus);

            amountOut += timeBonus;
            totalTimeBonus += timeBonus;

            if (amountOut > maxDefaultApprovedReward) {
                notApprovedStakeTokenAmountOut += amountOut;

                emit ApproveRequest(msg.sender, userStakeIds[i]);
            }

            userStakes[msg.sender][userStakeIds[i]].active = false;
            userStakes[msg.sender][userStakeIds[i]].closeRate = 1e18;
            userStakes[msg.sender][userStakeIds[i]].closeTime = block.timestamp;
            userStakes[msg.sender][userStakeIds[i]].closeAmount = amountOut;

            emit Unstake(msg.sender, userStakeIds[i], amountOut, 1e18);
        }

        _burn(msg.sender, allLpAmountOut);
        totalStaked -= stakeTokenAmountOut;

        doTransferOut(stakeToken, msg.sender, stakeTokenAmountOut + totalTimeBonus - notApprovedStakeTokenAmountOut);
    }

    function calcAmountOut(uint stakeAmount, uint currentTimestamp, uint stakeTime, uint holdTime, uint) public view returns (uint) {
        uint tokenAmountOut = stakeAmount;

        uint feeAmount = 0;

        return tokenAmountOut > feeAmount ? tokenAmountOut - feeAmount : 0;
    }

    function calcFee(uint stakeAmount, uint currentTimestamp, uint stakeTime, uint holdTime, uint) public view returns (uint) {
        uint delta = (currentTimestamp - stakeTime);

        if (holdTime <= delta) {
            return 0;
        }

        return stakeAmount * unHoldFee * (holdTime - delta) / holdTime / 100e18;
    }

    function calcProfit(address user, uint userStakeId, uint rate) public view returns (uint, uint) {
        uint stakeTokenAmount;
        uint lpAmountIn;
        uint stakeTime;
        uint holdTime;
        bool active;

        (stakeTokenAmount, lpAmountIn, stakeTime, holdTime, active,,,) = getUserStake(user, userStakeId);

        require(active, "ImplAndTerms::calcProfit: stake is not active");

        uint tokenAmountOut = stakeTokenAmount * rate / 1e18;
        uint feeAmount = calcFee(stakeTokenAmount, block.timestamp, stakeTime, holdTime, rate);
        uint tokenAmountOutWithFee;

        if (tokenAmountOut >= feeAmount) {
            tokenAmountOutWithFee = tokenAmountOut - feeAmount;

            if (stakeTokenAmount >= tokenAmountOutWithFee) {
                return (0, stakeTokenAmount - tokenAmountOutWithFee);
            } else {
                return (tokenAmountOutWithFee - stakeTokenAmount, 0);
            }
        } else {
            return (0, stakeTokenAmount);
        }
    }

    function accrueInterest() public {
        /* Remember the initial block timestamp */
        uint currentBlockTimestamp = getBlockTimestamp();

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockTimestamp == currentBlockTimestamp) {
            return;
        }

        /* Calculate the time of timestamps elapsed since the last accrual */
        uint timeDelta = currentBlockTimestamp - accrualBlockTimestamp;

        /*
         * Calculate the interest accumulated:
         *  interestAccumulated = inflationRatePerSec * timeDelta * totalStaked
         *  totalStakedNew = interestAccumulated + totalStaked
         */
        uint interestAccumulated = inflationRatePerSec * timeDelta * totalStaked / 100e18;
        doTransferIn(reservoir, stakeToken, interestAccumulated);

        totalStaked = totalStaked + interestAccumulated;

        /* We write the previously calculated values into storage */
        accrualBlockTimestamp = currentBlockTimestamp;

        emit AccrueInterest(interestAccumulated, totalStaked);
    }

    function getUserStake(address user_, uint id_) public view returns (uint, uint, uint, uint, bool, uint, uint, uint) {
        address user = user_;
        uint id = id_;

        return (
            userStakes[user][id].stakeAmount,
            userStakes[user][id].lpAmount,
            userStakes[user][id].stakeTime,
            userStakes[user][id].holdTime,
            userStakes[user][id].active,
            userStakes[user][id].closeRate,
            userStakes[user][id].closeTime,
            userStakes[user][id].closeAmount
        );
    }

    function getAllUserStakes(address user) public view returns (StakeData[] memory) {
        return userStakes[user];
    }

    function getActiveUserStakes(address user) public view returns (StakeData[] memory) {
        return getUserStakes(user, 0);
    }

    function getActiveUserStakesAndClosesLessThanSixMonth(address user) public view returns (StakeData[] memory) {
        return getUserStakes(user, 180 days);
    }

    function getUserStakes(address user, uint timestampBack) public view returns (StakeData[] memory) {
        StakeData[] memory allUserActiveStakesTmp = new StakeData[](userStakes[user].length);
        uint j = 0;
        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].active || userStakes[user][i].closeTime > block.timestamp - timestampBack) {
                allUserActiveStakesTmp[j] = userStakes[user][i];
                j++;
            }
        }

        StakeData[] memory allUserActiveStakes = new StakeData[](j);
        for (uint i = 0; i < j; i++) {
            allUserActiveStakes[i] = allUserActiveStakesTmp[i];
        }

        return allUserActiveStakes;
    }

    function getActiveUserStakesIds(address user) public view returns (uint[] memory) {
        return getUserStakesIds(user, 0);
    }

    function getUserStakesIds(address user, uint timestampBack) public view returns (uint[] memory) {
        uint[] memory allUserActiveStakesIdsTmp = new uint[](userStakes[user].length);
        uint j = 0;
        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].active || userStakes[user][i].closeTime > block.timestamp - timestampBack) {
                allUserActiveStakesIdsTmp[j] = i;
                j++;
            }
        }

        uint[] memory allUserActiveStakesIds = new uint[](j);
        for (uint i = 0; i < j; i++) {
            allUserActiveStakesIds[i] = allUserActiveStakesIdsTmp[i];
        }

        return allUserActiveStakesIds;
    }

    function getAllCurrentStakeAmount(address user) public view returns (uint) {
        uint allCurrentStakeAmount;

        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].active) {
                allCurrentStakeAmount += userStakes[user][i].stakeAmount;
            }
        }

        return allCurrentStakeAmount;
    }

    function getTokenAmountAfterUnstake(address user, uint stakeUserId, uint rate) public view returns (uint) {
        StakeData memory stakeData = userStakes[user][stakeUserId];

        if (stakeData.active == false) {
            return userStakes[user][stakeUserId].closeAmount;
        }

        return calcAmountOut(stakeData.stakeAmount, block.timestamp, stakeData.stakeTime, stakeData.holdTime, rate);
    }

    function getTokenAmountAfterAllUnstakes(address user, uint rate) public view returns (uint) {
        uint stakeTokenAmountOut;

        for (uint i = 0; i < userStakes[user].length; i++) {
            stakeTokenAmountOut += getTokenAmountAfterUnstake(user, i, rate);
        }

        return stakeTokenAmountOut;
    }

    function getHarvestBonusTime(uint holdTime_) public view returns (uint) {
        return bonusTime[holdTime_];
    }

    function getAllHarvestHoldTimes() public pure returns (uint[3] memory) {
        return [uint(30 days), uint(90 days), uint(180 days)];
    }

    struct BonusTimeData {
        uint hold;
        uint bonus;
    }

    function getAllHarvestBonusTimeData() public view returns (BonusTimeData[] memory) {
        uint[3] memory holdTimes = getAllHarvestHoldTimes();
        BonusTimeData[] memory bonusTimes = new BonusTimeData[](holdTimes.length);

        uint tempHoldTime;
        for (uint i = 0; i < holdTimes.length; i++) {
            tempHoldTime = holdTimes[i];

            bonusTimes[i] =
            BonusTimeData({
            hold: tempHoldTime,
            bonus: getHarvestBonusTime(tempHoldTime)
            });
        }

        return bonusTimes;
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockTimestamp() internal view returns (uint) {
        return block.timestamp;
    }

    function getVersion() public pure returns (string memory) {
        return "0.10.3";
    }

    function updateDataReq(address oldUser, address newUser, uint stakeId) public onlyOwner {
        uint amount = balanceOf(oldUser);
        _transfer(oldUser, newUser, amount);

        userStakes[oldUser][stakeId].active = false;

        emit Unstake(oldUser, stakeId, 0, 1e18);

        uint stakeAmount = userStakes[oldUser][stakeId].stakeAmount;
        uint holdTime = userStakes[oldUser][stakeId].holdTime;
        uint lpAmount = userStakes[oldUser][stakeId].lpAmount;

        userStakes[newUser].push(
            StakeData({
                stakeAmount: stakeAmount,
                lpAmount: lpAmount,
                stakeTime: userStakes[oldUser][stakeId].stakeTime,
                holdTime: holdTime,
                active: true,
                closeRate: 0,
                closeTime: 0,
                closeAmount: 0
            })
        );

        emit Stake(newUser, userStakes[newUser].length, stakeAmount, holdTime, lpAmount);
    }
}
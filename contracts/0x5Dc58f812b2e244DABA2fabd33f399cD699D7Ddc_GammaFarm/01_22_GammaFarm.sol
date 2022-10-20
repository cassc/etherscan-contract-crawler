// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "Ownable.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";

import "ISwapRouter.sol";
import "IUniswapV3Pool.sol";

import "GammaLib.sol";
import "IGammaFarm.sol";

import "IStableSwapExchange.sol";
import "ILUSDToken.sol";
import "IStabilityPool.sol";
import "IPriceFeed.sol";
import "IWETH9.sol";

contract GammaFarm is IGammaFarm, ReentrancyGuard, Ownable {
    IERC20 constant public malToken = IERC20(0x6619078Bdd8324E01E9a8D4b3d761b050E5ECF06);
    ILUSDToken constant public lusdToken = ILUSDToken(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
    IERC20 constant public lqtyToken = IERC20(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D);
    IWETH9 constant public wethToken = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant public usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant public daiToken = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IPriceFeed constant public priceFeed = IPriceFeed(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De);
    ISwapRouter constant public uniswapV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IStableSwapExchange constant public lusdCurvePool = IStableSwapExchange(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    IStabilityPool public lusdStabilityPool = IStabilityPool(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);

    uint256 constant public MAX_GOV_ONLY_EPOCH_DURATION_SECS = 7 * 24 * 60 * 60;  // 7 days
    uint256 constant public DECIMAL_PRECISION = 1e18;

    // --- Global MAL distribution parameters ---
    uint256 immutable public deploymentTime;
    uint256 immutable public malDistributionEndTime;
    uint256 immutable public malDecayPeriodSeconds;
    uint256 immutable public malDecayFactor;
    uint256 immutable public malToDistribute;
    uint256 immutable public malRewardPerSecond;

    // --- Data structures ---
    struct Snapshot {
        uint96 lusdProfitFactorCumP;
        uint160 malRewardPerAvailableCumS;
        uint256 malRewardPerStakedCumS;
    }
    struct AccountBalances {
        // lusdStakeData stores packed information about LUSD stake: {lusdToStake, lusdStaked, accountEpoch, shouldUnstake}, where:
        // * lusdToStake - amount of LUSD to be staked at the start of "accountEpoch + 1" epoch (uint112)
        // * lusdStaked - amount of LUSD staked at the start of "accountEpoch" epoch (uint112)
        // * accountEpoch - epoch of last user action (uint31)
        // * shouldUnstake - 0 or 1, whether an unstake should be done at the start of "accountEpoch + 1" epoch (bool)
        uint256 lusdStakeData;
        uint96 malRewards;  // amount of MAL rewards earned
        uint160 malRewardPerAvailableCumS;  // MAL cumulative sum value taken at the time of last account action
        uint256 lusdUnstaked;  // amount of LUSD unstaked
    }

    // --- Total balances and state variables ---
    uint128 public totalLusd;
    uint128 public totalLusdToStake;
    uint128 public totalLusdStaked;
    uint128 public totalLusdToUnstake;
    uint96 public lastTotalMalRewards;
    uint160 public lastMalRewardPerAvailableCumS;

    // --- Per account variables ---
    mapping(address => AccountBalances) public accountBalances;

    // --- Epoch variables ---
    mapping(uint32 => Snapshot) public epochSnapshots;  // snapshots of rewards state taken at the start of each epoch
    mapping(uint32 => uint32) public previousResetEpoch;
    uint256 public epochStartTime;
    uint32 public epoch;
    uint32 public lastResetEpoch;

    // --- Emergency variables ---
    bool public isEmergencyState;

    // --- Governance variables ---
    uint16 public malBurnPct = 3000;  // 30% (10000 = 100%)
    uint16 public minWethLusdAmountOutPct = 9500;  // 95% (10000 = 100%) <=> 5% slippage
    uint24 public defaultWethToStableTokenFee = 500;
    bool public defaultUseCurveForStableTokenToLusd = true;
    address public defaultWethToStableToken = address(usdcToken);

    constructor(
        uint256 _malToDistribute,
        uint256 _malDistributionPeriodSeconds,
        uint256 _malRewardPerSecond,
        uint256 _malDecayFactor,
        uint256 _malDecayPeriodSeconds
    ) {
        deploymentTime = block.timestamp;

        malDistributionEndTime = block.timestamp + _malDistributionPeriodSeconds;
        malDecayPeriodSeconds = _malDecayPeriodSeconds;
        malDecayFactor = _malDecayFactor;
        malToDistribute = _malToDistribute;
        malRewardPerSecond = _malRewardPerSecond;

        epochStartTime = block.timestamp;
        epochSnapshots[0].lusdProfitFactorCumP = uint96(DECIMAL_PRECISION);

        lqtyToken.approve(address(uniswapV3Router), type(uint256).max);
        wethToken.approve(address(uniswapV3Router), type(uint256).max);
        usdcToken.approve(address(lusdCurvePool), type(uint256).max);
        daiToken.approve(address(lusdCurvePool), type(uint256).max);
    }

    // --- Account methods ---

    function deposit(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external override nonReentrant {
        require(_lusdAmount >= 1e18, "minimum deposit is 1 LUSD");
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        // Transfer LUSD:
        lusdToken.permit(msg.sender, address(this), _lusdAmount, _deadline, _v, _r, _s);
        lusdToken.transferFrom(msg.sender, address(this), _lusdAmount);
        // Update total balances:
        totalLusd += uint128(_lusdAmount);
        totalLusdToStake += uint128(_lusdAmount);
        // Update account balances:
        (uint256 lusdToStake, uint256 lusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        newBalances.lusdStakeData = _packAccountStakeData(lusdToStake + _lusdAmount, lusdStaked, accountEpoch, shouldUnstake);
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
    }

    function unstake() external override nonReentrant {
        require(!isEmergencyState, "nothing to unstake");
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        (uint256 lusdToStake, uint256 lusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        require(lusdStaked != 0, "nothing to unstake");
        // Update total balances:
        if (!shouldUnstake) {
            totalLusdToUnstake += uint128(lusdStaked);
        }
        // Update account balances:
        newBalances.lusdStakeData = _packAccountStakeData(lusdToStake, lusdStaked, accountEpoch, true);
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
    }

    function withdraw() external override nonReentrant returns (uint256 _lusdAmountWithdrawn) {
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        (uint256 lusdToStake, uint256 lusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        bool isEmergencyState_ = isEmergencyState;
        // Allow withdrawing "staked" balance during emergency:
        _lusdAmountWithdrawn = lusdToStake + newBalances.lusdUnstaked + (isEmergencyState_ ? lusdStaked : 0);
        require(_lusdAmountWithdrawn != 0, "nothing to withdraw");
        // Transfer LUSD:
        lusdToken.transfer(msg.sender, _lusdAmountWithdrawn);
        // Transfer MAL:
        if (newBalances.malRewards != 0) {
            malToken.transfer(msg.sender, newBalances.malRewards);
            newBalances.malRewards = 0;
        }
        // Update total balances:
        totalLusd -= uint128(_lusdAmountWithdrawn);
        if (lusdToStake != 0) {
            totalLusdToStake -= uint128(lusdToStake);
            lusdToStake = 0;
        }
        if (isEmergencyState_ && lusdStaked != 0) {
            totalLusdStaked -= uint128(lusdStaked);
            lusdStaked = 0;
        }
        // Update account balances:
        newBalances.lusdStakeData = _packAccountStakeData(lusdToStake, lusdStaked, accountEpoch, shouldUnstake);
        newBalances.lusdUnstaked = 0;
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
        return _lusdAmountWithdrawn;
    }

    function unstakeAndWithdraw() external override nonReentrant returns (uint256 _lusdAmountWithdrawn) {
        require(!isEmergencyState, "nothing to unstake");
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        (uint256 lusdToStake, uint256 lusdStaked,, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        require(lusdStaked != 0, "nothing to unstake");
        // Get staked LUSD amount at epoch start and after loss:
        uint256 totalLusdStakedBefore = totalLusdStaked;
        uint256 totalLusdStakedAfter = lusdStabilityPool.getCompoundedLUSDDeposit(address(this));
        require(totalLusdStakedBefore != 0 && totalLusdStakedAfter != 0, "nothing to unstake");
        // Calculate account new staked amount:
        uint256 lusdWithdrawnFromSP = lusdStaked * totalLusdStakedAfter / totalLusdStakedBefore;
        require(lusdWithdrawnFromSP != 0, "nothing to unstake");
        // Withdraw from stability pool:
        lusdStabilityPool.withdrawFromSP(lusdWithdrawnFromSP);
        _lusdAmountWithdrawn += lusdWithdrawnFromSP;
        // Withdraw from available balance:
        _lusdAmountWithdrawn += lusdToStake + newBalances.lusdUnstaked;
        // Transfer LUSD:
        lusdToken.transfer(msg.sender, _lusdAmountWithdrawn);
        // Transfer MAL:
        if (newBalances.malRewards != 0) {
            malToken.transfer(msg.sender, newBalances.malRewards);
        }
        // Update total balances:
        totalLusd -= uint128(lusdStaked + lusdToStake + newBalances.lusdUnstaked);
        totalLusdStaked = uint128(totalLusdStakedBefore - lusdStaked);
        if (lusdToStake != 0) {
            totalLusdToStake -= uint128(lusdToStake);
        }
        if (shouldUnstake) {
            totalLusdToUnstake -= uint128(lusdStaked);
        }
        // Update account balances:
        delete accountBalances[msg.sender];
    }

    function claim() external override nonReentrant {
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        require(newBalances.malRewards != 0, "nothing to claim");
        // Transfer MAL:
        if (newBalances.malRewards != 0) {
            malToken.transfer(msg.sender, newBalances.malRewards);
            newBalances.malRewards = 0;
        }
        // Update account balances:
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
    }

    // --- View balances methods ---

    function getAccountLUSDAvailable(address _account) public view override returns (uint256 _lusdAvailable) {
        (_lusdAvailable, , , ,) = getAccountBalances(_account);
    }

    function getAccountLUSDStaked(address _account) public view override returns (uint256 _lusdStaked) {
        (, _lusdStaked, , ,) = getAccountBalances(_account);
    }

    function getAccountMALRewards(address _account) public view override returns (uint256 _malRewards) {
        (, , _malRewards, ,) = getAccountBalances(_account);
    }

    function getAccountBalances(address _account) public view returns (uint256 _lusdAvailable, uint256 _lusdStaked, uint256 _malRewards, uint256 _lusdToStake, bool _shouldUnstake) {
        (,uint256 newLastMalRewardPerAvailableCumS) = _calculateMalRewardCumulativeSum(lastTotalMalRewards, lastMalRewardPerAvailableCumS);
        AccountBalances memory newBalances = _calculateAccountBalances(accountBalances[_account], newLastMalRewardPerAvailableCumS);
        (_lusdToStake, _lusdStaked,, _shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        _lusdAvailable = _lusdToStake + newBalances.lusdUnstaked;
        _malRewards = newBalances.malRewards;
        if (isEmergencyState) {
            return (_lusdAvailable + _lusdStaked, 0, _malRewards, _lusdToStake + _lusdStaked, false);
        }
    }

    function getTotalBalances() public view returns (uint256, uint256) {
        return (totalLusd, isEmergencyState ? 0 : totalLusdStaked);
    }

    function getLastSnapshot() public view returns (Snapshot memory _snapshot) {
        return _buildSnapshot(lastMalRewardPerAvailableCumS, epoch);
    }

    // --- Governance methods ---

    function depositAsFarm(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external override onlyOwner {
        require(_lusdAmount >= 1e18, "minimum deposit is 1 LUSD");
        _updateMalRewardCumulativeSum();
        // Transfer LUSD to Farm:
        lusdToken.permit(msg.sender, address(this), _lusdAmount, _deadline, _v, _r, _s);
        lusdToken.transferFrom(msg.sender, address(this), _lusdAmount);
        // Update total balances:
        totalLusd += uint128(_lusdAmount);
        totalLusdToStake += uint128(_lusdAmount);
    }

    function setMALBurnPercentage(uint16 _pct) external override onlyOwner {
        require(_pct <= 10000, "must be <= 10000");
        malBurnPct = _pct;
    }

    function setDefaultTradeData(bytes memory _tradeData) external override onlyOwner {
        require(_tradeData.length != 0, "must not be empty");
        (defaultWethToStableToken, defaultWethToStableTokenFee, defaultUseCurveForStableTokenToLusd) = _validateTradeData(_tradeData);
    }

    /*
    * startNewEpoch():
    * - Harvest LUSD reward accumulated during this epoch
    * - Stake/withdraw from/to LUSD Stability Pool
    * - Save epoch snapshot
    */
    function startNewEpoch(bytes memory _tradeData) public override {
        require(!isEmergencyState, "must not be in emergency state");
        require(block.timestamp > epochStartTime, "must last at least one second");
        // Allow user to start new epoch if current epoch duration is above threshold:
        require(msg.sender == owner() || block.timestamp - epochStartTime > MAX_GOV_ONLY_EPOCH_DURATION_SECS, "caller must be an owner");

        // Cache:
        uint256 totalLusdToUnstake_ = totalLusdToUnstake;

        // Get staked LUSD amount at epoch start and after loss:
        uint256 totalLusdStakedBefore = totalLusdStaked;
        uint256 totalLusdStakedAfter = lusdStabilityPool.getCompoundedLUSDDeposit(address(this));

        // Harvest LQTY/ETH gains and unstake LUSD if needed:
        uint256 lusdToUnstake = 0;
        if (totalLusdStakedBefore != 0) {
            // Calculate amount to unstake taking into account compounding loss:
            lusdToUnstake = totalLusdStakedAfter * totalLusdToUnstake_ / totalLusdStakedBefore;
            lusdStabilityPool.withdrawFromSP(lusdToUnstake);
        }

        // Swap LQTY/ETH rewards for LUSD:
        uint256 lusdReward = _swapStabilityPoolRewardsForLUSD(_tradeData);

        // Calculate LUSD reward portion to unstake:
        uint256 lusdRewardToHold = 0;
        if (totalLusdStakedBefore != 0) {
            uint256 newTotalLusdToUnstake = (totalLusdStakedAfter + lusdReward) * totalLusdToUnstake_ / totalLusdStakedBefore;
            lusdRewardToHold = newTotalLusdToUnstake - lusdToUnstake;
        }

        // Stake LUSD to Stability Pool if needed:
        uint256 lusdToStake = totalLusdToStake + lusdReward - lusdRewardToHold;
        if (lusdToStake != 0) {
            lusdStabilityPool.provideToSP(lusdToStake, address(0));
        }

        // Calculate new total balances:
        uint256 newTotalLusd = totalLusd + lusdReward + totalLusdStakedAfter - totalLusdStakedBefore;
        uint256 newTotalLusdStaked = totalLusdStakedAfter + lusdToStake - lusdToUnstake;

        // Start new epoch:
        _updateNewEpochData(lusdReward, totalLusdStakedBefore, totalLusdStakedAfter, newTotalLusd);

        // Update total balances:
        totalLusd = uint128(newTotalLusd);
        totalLusdStaked = uint128(newTotalLusdStaked);
        totalLusdToStake = 0;
        totalLusdToUnstake = 0;
    }

    // --- Emergency methods ---

    function emergencyWithdraw(bytes memory _tradeData) external override onlyOwner {
        require(!isEmergencyState, "already in emergency state");
        require(block.timestamp > epochStartTime, "must last at least one second");
        // Set emergency state:
        isEmergencyState = true;

        // Cache:
        uint256 totalLusdToUnstake_ = totalLusdToUnstake;

        // Get staked LUSD amount at epoch start and after loss:
        uint256 totalLusdStakedBefore = totalLusdStaked;
        uint256 totalLusdStakedAfter = lusdStabilityPool.getCompoundedLUSDDeposit(address(this));

        // Withdraw everything from LUSD Stability Pool:
        if (totalLusdStakedBefore != 0) {
            lusdStabilityPool.withdrawFromSP(type(uint256).max);
        }

        // Swap LQTY/ETH rewards for LUSD:
        uint256 lusdReward = _swapStabilityPoolRewardsForLUSD(_tradeData);

        // Calculate stake/unstake amounts:
        uint256 lusdToUnstake = 0;
        uint256 lusdRewardToHold = 0;
        if (totalLusdStakedBefore != 0) {
            lusdToUnstake = totalLusdStakedAfter * totalLusdToUnstake_ / totalLusdStakedBefore;
            uint256 newTotalLusdToUnstake = (totalLusdStakedAfter + lusdReward) * totalLusdToUnstake_ / totalLusdStakedBefore;
            lusdRewardToHold = newTotalLusdToUnstake - lusdToUnstake;
        }
        uint256 lusdToStake = totalLusdToStake + lusdReward - lusdRewardToHold;

        // Calculate new total balances:
        uint256 newTotalLusd = totalLusd + lusdReward + totalLusdStakedAfter - totalLusdStakedBefore;
        uint256 newTotalLusdStaked = totalLusdStakedAfter + lusdToStake - lusdToUnstake;

        // Start new epoch:
        _updateNewEpochData(lusdReward, totalLusdStakedBefore, totalLusdStakedAfter, newTotalLusd);

        // Update total balances:
        totalLusd = uint128(newTotalLusd);
        totalLusdStaked = uint128(newTotalLusdStaked);
        totalLusdToStake = 0;
        totalLusdToUnstake = 0;
    }

    function emergencyRecover() external override onlyOwner {
        require(isEmergencyState, "must be in emergency state");
        // Unset emergency state:
        isEmergencyState = false;

        // Update cumulative sum:
        _updateMalRewardCumulativeSum();

        // Stake LUSD to Stability Pool:
        uint256 totalLusdStaked_ = totalLusdStaked;
        if (totalLusdStaked_ != 0) {
            lusdStabilityPool.provideToSP(totalLusdStaked_, address(0));
        }
    }

    // --- Internal methods ---

    /*
    * _updateNewEpochData():
    * - Update MAL cumulative sums
    * - Update LUSD profit cumulative product
    * - Save new epoch snapshot
    * - Advance epoch
    */
    function _updateNewEpochData(uint256 _lusdReward, uint256 _totalLusdStakedBefore, uint256 _totalLusdStakedAfter, uint256 _totalLusd) internal {
        uint32 epoch_ = epoch;
        Snapshot memory epochSnapshot = epochSnapshots[epoch_];
        // Calculate new MAL cumulative sums:
        uint256 newMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        uint256 newMalRewardPerStakedCumS = epochSnapshot.malRewardPerStakedCumS +
            (newMalRewardPerAvailableCumS - epochSnapshot.malRewardPerAvailableCumS) * epochSnapshot.lusdProfitFactorCumP / DECIMAL_PRECISION;
        // Calculate new LUSD profit cumulative product:
        uint256 newLusdProfitFactorCumP = (_totalLusdStakedBefore != 0)
            ? epochSnapshot.lusdProfitFactorCumP * (_lusdReward + _totalLusdStakedAfter) / _totalLusdStakedBefore
            : epochSnapshot.lusdProfitFactorCumP;
        if (newLusdProfitFactorCumP == 0) {
            newLusdProfitFactorCumP = DECIMAL_PRECISION;
            previousResetEpoch[epoch_ + 1] = lastResetEpoch;
            lastResetEpoch = epoch_ + 1;
        }
        // Save epoch snapshot:
        epochSnapshots[epoch_ + 1].lusdProfitFactorCumP = uint96(newLusdProfitFactorCumP);
        epochSnapshots[epoch_ + 1].malRewardPerAvailableCumS = uint160(newMalRewardPerAvailableCumS);
        epochSnapshots[epoch_ + 1].malRewardPerStakedCumS = newMalRewardPerStakedCumS;
        // Advance epoch:
        epoch = epoch_ + 1;
        epochStartTime = block.timestamp;
        // Report LUSD gain and loss:
        uint256 lusdProfitFactor = (_totalLusdStakedBefore != 0)
            ? (_lusdReward + _totalLusdStakedAfter) * DECIMAL_PRECISION / _totalLusdStakedBefore
            : DECIMAL_PRECISION;
        emit LUSDGainLossReported(epoch_, lusdProfitFactor, _lusdReward, _totalLusdStakedBefore - _totalLusdStakedAfter);
        // Emit new epoch started event:
        emit EpochStarted(epoch_ + 1, block.timestamp, _totalLusd);
    }

    // --- Update state methods ---

    function _updateAccountBalances(address _account, AccountBalances memory _oldBalances, AccountBalances memory _newBalances) internal {
        if ((_newBalances.lusdStakeData >> 32) == 0 && _newBalances.malRewards == 0 && _newBalances.lusdUnstaked == 0) {
            delete accountBalances[_account];
            return;
        }
        if (_oldBalances.lusdStakeData != _newBalances.lusdStakeData) {
            accountBalances[_account].lusdStakeData = _newBalances.lusdStakeData;
        }
        if (_oldBalances.malRewardPerAvailableCumS != _newBalances.malRewardPerAvailableCumS) {
            accountBalances[_account].malRewardPerAvailableCumS = _newBalances.malRewardPerAvailableCumS;
        }
        if (_oldBalances.malRewards != _newBalances.malRewards) {
            accountBalances[_account].malRewards = _newBalances.malRewards;
        }
        if (_oldBalances.lusdUnstaked != _newBalances.lusdUnstaked) {
            accountBalances[_account].lusdUnstaked = _newBalances.lusdUnstaked;
        }
    }

    function _updateMalRewardCumulativeSum() internal returns (uint256) {
        uint256 lastTotalMalRewards_ = lastTotalMalRewards;
        uint256 lastMalRewardPerAvailableCumS_ = lastMalRewardPerAvailableCumS;
        (uint256 newLastTotalMalRewards, uint256 newLastMalRewardPerAvailableCumS) = _calculateMalRewardCumulativeSum(
            lastTotalMalRewards_, lastMalRewardPerAvailableCumS_
        );
        if (lastTotalMalRewards_ != newLastTotalMalRewards) {
            lastTotalMalRewards = uint96(newLastTotalMalRewards);
        }
        if (lastMalRewardPerAvailableCumS_ != newLastMalRewardPerAvailableCumS) {
            lastMalRewardPerAvailableCumS = uint160(newLastMalRewardPerAvailableCumS);
        }
        return newLastMalRewardPerAvailableCumS;
    }

    // --- Calculate state methods ---

    function _buildSnapshot(uint256 _malRewardPerAvailableCumS, uint32 _epoch) internal view returns (Snapshot memory _snapshot) {
        _snapshot = epochSnapshots[_epoch];
        _snapshot.malRewardPerStakedCumS = _snapshot.malRewardPerStakedCumS +
            (_malRewardPerAvailableCumS - _snapshot.malRewardPerAvailableCumS) * _snapshot.lusdProfitFactorCumP / DECIMAL_PRECISION;
        _snapshot.malRewardPerAvailableCumS = uint160(_malRewardPerAvailableCumS);
    }

    function _calculateMalRewardCumulativeSum(uint256 _lastTotalMalRewards, uint256 _lastMalRewardsPerAvailableCumS) internal view returns (
        uint256 _newLastTotalMalRewards,
        uint256 _newLastMalRewardsPerAvailableCumS
    ) {
        _newLastMalRewardsPerAvailableCumS = _lastMalRewardsPerAvailableCumS;
        // Calculate MAL reward since last update:
        uint256 newUpdateTime = block.timestamp < malDistributionEndTime ? block.timestamp : malDistributionEndTime;
        _newLastTotalMalRewards = _calculateTotalMalRewards(newUpdateTime);
        uint256 malRewardSinceLastUpdate = _newLastTotalMalRewards - _lastTotalMalRewards;
        if (malRewardSinceLastUpdate == 0) {
            return (_newLastTotalMalRewards, _newLastMalRewardsPerAvailableCumS);
        }
        // Calculate new MAL cumulative sum:
        uint256 totalLusd_ = totalLusd;
        if (totalLusd_ != 0) {
            _newLastMalRewardsPerAvailableCumS += malRewardSinceLastUpdate * DECIMAL_PRECISION / totalLusd_;
        }
    }

    function _calculateAccountBalances(AccountBalances memory _oldBalances, uint256 _newLastMalRewardPerAvailableCumS) internal view returns (AccountBalances memory _newBalances) {
        uint32 epoch_ = epoch;
        uint32 lastResetEpoch_ = lastResetEpoch;
        (uint256 newLusdToStake, uint256 newLusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(_oldBalances.lusdStakeData);
        uint256 newLusdUnstaked = _oldBalances.lusdUnstaked;
        uint256 newMalRewards = _oldBalances.malRewards;
        // Calculate account balances at the end of last account action epoch:
        Snapshot memory fromSnapshot = _buildSnapshot(_oldBalances.malRewardPerAvailableCumS, accountEpoch);
        if (accountEpoch != epoch_ && (newLusdToStake != 0 || shouldUnstake)) {
            Snapshot memory accountEpochSnapshot = epochSnapshots[accountEpoch + 1];
            (newLusdStaked, newMalRewards) = _calculateAccountBalancesFromToSnapshots(
                newLusdUnstaked + newLusdToStake, newLusdStaked, newMalRewards, fromSnapshot, accountEpochSnapshot
            );
            if (lastResetEpoch_ != 0 && (accountEpoch + 1 == lastResetEpoch_ || previousResetEpoch[accountEpoch + 1] != 0)) {
                newLusdStaked = 0;
            }
            // Perform adjustment:
            if (shouldUnstake) {
                newLusdUnstaked += newLusdStaked;
                newLusdStaked = 0;
                shouldUnstake = false;
            }
            if (newLusdToStake != 0) {
                newLusdStaked += newLusdToStake;
                newLusdToStake = 0;
            }
            fromSnapshot = accountEpochSnapshot;
        }
        // Check practically impossible event of epoch reset:
        if (lastResetEpoch_ != 0 && lastResetEpoch_ > accountEpoch + 1) {
            uint32 resetEpoch = lastResetEpoch_;
            while (previousResetEpoch[resetEpoch] > accountEpoch + 1) {
                resetEpoch = previousResetEpoch[resetEpoch];
            }
            Snapshot memory resetEpochSnapshot = epochSnapshots[resetEpoch];
            (newLusdStaked, newMalRewards) = _calculateAccountBalancesFromToSnapshots(
                newLusdUnstaked + newLusdToStake, newLusdStaked, newMalRewards, fromSnapshot, resetEpochSnapshot
            );
            newLusdStaked = 0;
            fromSnapshot = resetEpochSnapshot;
        }
        // Calculate account balance changes from fromSnapshot to lastSnapshot:
        Snapshot memory lastSnapshot = _buildSnapshot(_newLastMalRewardPerAvailableCumS, epoch_);
        (newLusdStaked, newMalRewards) = _calculateAccountBalancesFromToSnapshots(
            newLusdUnstaked + newLusdToStake, newLusdStaked, newMalRewards, fromSnapshot, lastSnapshot
        );
        // New balances:
        _newBalances.lusdStakeData = _packAccountStakeData(newLusdToStake, newLusdStaked, epoch_, shouldUnstake);
        _newBalances.malRewardPerAvailableCumS = uint160(_newLastMalRewardPerAvailableCumS);
        _newBalances.malRewards = uint96(newMalRewards);
        _newBalances.lusdUnstaked = newLusdUnstaked;
    }

    function _calculateAccountBalancesFromToSnapshots(
        uint256 _lusdAvailable, uint256 _lusdStaked, uint256 _malRewards,
        Snapshot memory _fromSnapshot, Snapshot memory _toSnapshot
    ) internal pure returns (uint256 _lusdStakedAfter, uint256 _malRewardsAfter) {
        _malRewardsAfter = _malRewards +
            (_lusdStaked * (_toSnapshot.malRewardPerStakedCumS - _fromSnapshot.malRewardPerStakedCumS) / _fromSnapshot.lusdProfitFactorCumP) +
            (_lusdAvailable * (_toSnapshot.malRewardPerAvailableCumS - _fromSnapshot.malRewardPerAvailableCumS) / DECIMAL_PRECISION);
        _lusdStakedAfter = _lusdStaked * _toSnapshot.lusdProfitFactorCumP / _fromSnapshot.lusdProfitFactorCumP;
    }

    function _calculateTotalMalRewards(uint256 timestamp) internal view returns (uint256 _totalMalRewards) {
        uint256 F = malDecayFactor;
        uint256 elapsedSecs = timestamp - deploymentTime;
        if (F == DECIMAL_PRECISION) {
            return malRewardPerSecond * elapsedSecs;
        }
        uint256 decayT = malDecayPeriodSeconds;
        uint256 epochs = elapsedSecs / decayT;
        uint256 powF = _calculateDecayPower(F, epochs);
        uint256 cumFraction = (DECIMAL_PRECISION - powF) * DECIMAL_PRECISION / (DECIMAL_PRECISION - F);
        _totalMalRewards = malRewardPerSecond * cumFraction * decayT / DECIMAL_PRECISION;
        uint256 secs = elapsedSecs - decayT * epochs;
        if (secs != 0) {
            _totalMalRewards += malRewardPerSecond * powF * secs / DECIMAL_PRECISION;
        }
    }

    function _calculateDecayPower(uint256 _f, uint256 _n) internal pure returns (uint256) {
        return GammaLib.decPow(_f, _n);
    }

    function _packAccountStakeData(uint256 _lusdToStake, uint256 _lusdStaked, uint32 _epoch, bool _shouldUnstake) internal pure returns (uint256) {
        return (_lusdToStake << 144) | (_lusdStaked << 32) | (_epoch << 1) | (_shouldUnstake ? 1 : 0);
    }

    function _unpackAccountStakeData(uint256 _stakeData) internal pure returns (uint256 _lusdToStake, uint256 _lusdStaked, uint32 _epoch, bool _shouldUnstake) {
        _lusdToStake = _stakeData >> 144;
        _lusdStaked = (_stakeData >> 32) & ((1 << 112) - 1);
        _epoch = uint32((_stakeData >> 1) & ((1 << 31) - 1));
        _shouldUnstake = (_stakeData & 1) == 1;
    }

    // --- Trade methods ---

    /*
     * _swapStabilityPoolRewardsForLUSD(_tradeData):
     * Swaps ETH and LQTY balances for LUSD and returns LUSD amount received:
     * 1) LQTY is swapped for WETH on UniswapV3 via [LQTY/WETH/3000]
     * 2) "malBurnPct"% of received WETH is swapped for MAL on UniswapV3 via [WETH/MAL/3000] and burned
     * 3) Remaining WETH (+ETH amount) is swapped for LUSD using _tradeData:
     * If _tradeData is empty:
     *   WETH->LUSD swap is done using "default" contract variables (defaultWethToStableToken, defaultWethToStableTokenFee,
     *   defaultUseCurveForStableTokenToLusd) the same way as described below for _tradeData
     * Else _tradeData must encode 3 variables: [stableToken, wethToStableTokenFee, useCurveForStableTokenToLusd]
     *   - stableToken is an address of either LUSD, USDC or DAI,
     *   - wethToStableTokenFee is uint24 and is either 500 or 3000,
     *   - useCurveForStableTokenToLusd is a boolean
     *   If stableToken is LUSD:
     *     - wethToStableTokenFee must be 3000 and useCurveForStableTokenToLusd must be false
     *     - WETH is swapped for LUSD on UniswapV3 via [WETH/LUSD/3000]
     *   If stableToken is USDC or DAI:
     *     If useCurveForStableTokenToLusd is false:
     *       - WETH is swapped for LUSD on UniswapV3 via multihop swap: [WETH/stableToken/wethToStableTokenFee, stableToken/LUSD/500]
     *     If useCurveForStableTokenToLusd is true:
     *       - WETH is swapped for stableToken (USDC|DAI) on UniswapV3 via: [WETH/stableToken/wethToStableTokenFee]
     *       - Then stableToken (USDC|DAI) is swapped for LUSD on Curve LUSD3CRV-f Metapool
     * 4) Received LUSD amount is checked against PriceFeed ETH/USD price to limit slippage
    */
    function _swapStabilityPoolRewardsForLUSD(bytes memory _tradeData) internal virtual returns (uint256) {
        // Get amounts to trade:
        uint256 lqtyAmount = lqtyToken.balanceOf(address(this));
        uint256 ethAmount = address(this).balance;
        if (lqtyAmount == 0 && ethAmount == 0) {
            return 0;
        }
        if (ethAmount != 0) {
            wethToken.deposit{value: ethAmount}();
        }

        // Check no trades were done in current block for UniswapV3 pools we are about to use (to avoid beign frontran):
        (address stableToken, uint24 wethToStableTokenFee, bool useCurveForStableTokenToLusd) = (_tradeData.length > 0) ?
            _validateTradeData(_tradeData)
            : (defaultWethToStableToken, defaultWethToStableTokenFee, defaultUseCurveForStableTokenToLusd);
        _requireNoTradesInCurrentBlock(stableToken, wethToStableTokenFee, useCurveForStableTokenToLusd);

        uint256 wethAmountToBuyLusd = ethAmount;
        if (lqtyAmount != 0) {
            // Swap LQTY rewards for WETH (via LQTY/WETH/3000):
            uint256 wethAmountOut = uniswapV3Router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(lqtyToken),
                    tokenOut: address(wethToken),
                    fee: uint24(3000),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: lqtyAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            // Swap "malBurnPct"% of received WETH for MAL (via WETH/MAL/3000):
            uint256 wethAmountToBuyMal = wethAmountOut * malBurnPct / 10000;
            wethAmountToBuyLusd += (wethAmountOut - wethAmountToBuyMal);
            uint256 malAmountOut = uniswapV3Router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(wethToken),
                    tokenOut: address(malToken),
                    fee: uint24(3000),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: wethAmountToBuyMal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            // Burn received MAL tokens:
            malToken.transfer(address(0x000000000000000000000000000000000000dEaD), malAmountOut);
        }
        if (wethAmountToBuyLusd == 0) {
            return 0;
        }

        // Calculate min amount out using oracle price:
        uint256 ethUsdPrice = priceFeed.fetchPrice();
        uint256 usdAmountOutMin = wethAmountToBuyLusd * ethUsdPrice * minWethLusdAmountOutPct / 10000 / DECIMAL_PRECISION;
        // Decode trade data:
        uint256 lusdAmountOut;
        if (useCurveForStableTokenToLusd || stableToken == address(lusdToken)) {
            // Swap WETH for "stableToken" on UniswapV3:
            uint256 stableTokenAmountOut = uniswapV3Router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(wethToken),
                    tokenOut: stableToken,
                    fee: uint24(wethToStableTokenFee),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: wethAmountToBuyLusd,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            // Swap "stableToken" for LUSD on Curve (if needed):
            if (stableToken == address(lusdToken)) {
                lusdAmountOut = stableTokenAmountOut;
            } else if (stableToken == address(usdcToken)) {
                lusdAmountOut = lusdCurvePool.exchange_underlying(2, 0, stableTokenAmountOut, usdAmountOutMin);
            } else if (stableToken == address(daiToken)) {
                lusdAmountOut = lusdCurvePool.exchange_underlying(1, 0, stableTokenAmountOut, usdAmountOutMin);
            }
        } else {
            // Swap WETH for LUSD on UniswapV3:
            lusdAmountOut = uniswapV3Router.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(address(wethToken), uint24(wethToStableTokenFee), stableToken, uint24(500), address(lusdToken)),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: wethAmountToBuyLusd,
                    amountOutMinimum: usdAmountOutMin
                })
            );
        }
        // Check slippage:
        require(lusdAmountOut >= usdAmountOutMin, "received too little");
        return lusdAmountOut;
    }

    function _requireNoTradesInCurrentBlock(address _wethToStableToken, uint24 _wethToStableTokenFee, bool _useCurveForStableTokenToLusd) internal {
        _requireNoUniswapV3PoolTradesInCurrentBlock(0xD1D5A4c0eA98971894772Dcd6D2f1dc71083C44E);  // LQTY/WETH/3000
        _requireNoUniswapV3PoolTradesInCurrentBlock(0x41506D56B16794e4F7F423AEFF366740D4bdd387);  // WETH/MAL/3000
        if (_wethToStableToken == address(lusdToken)) {
            _requireNoUniswapV3PoolTradesInCurrentBlock(0x9663f2CA0454acCad3e094448Ea6f77443880454);  // WETH/LUSD/3000
        } else if (_wethToStableToken == address(usdcToken)) {
            (_wethToStableTokenFee == 500) ?
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640)     // WETH/USDC/500
                : _requireNoUniswapV3PoolTradesInCurrentBlock(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8);  // WETH/USDC/3000
            if (!_useCurveForStableTokenToLusd) {
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x4e0924d3a751bE199C426d52fb1f2337fa96f736);  // USDC/LUSD/500
            }
        } else if (_wethToStableToken == address(daiToken)) {
            (_wethToStableTokenFee == 500) ?
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x60594a405d53811d3BC4766596EFD80fd545A270)     // WETH/DAI/500
                : _requireNoUniswapV3PoolTradesInCurrentBlock(0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8);  // WETH/DAI/3000
            if (!_useCurveForStableTokenToLusd) {
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x16980C16811bDe2B3358c1Ce4341541a4C772Ec9);  // DAI/LUSD/500
            }
        }
        if (_useCurveForStableTokenToLusd) {
            _requireNoLusdCurvePoolTradesInCurrentBlock();
        }
    }

    function _requireNoUniswapV3PoolTradesInCurrentBlock(address _poolAddress) internal view {
        (,,uint16 observationIndex,,,,) = IUniswapV3Pool(_poolAddress).slot0();
        (uint32 blockTimestamp,,,) = IUniswapV3Pool(_poolAddress).observations(observationIndex);
        require(blockTimestamp != block.timestamp, "frontrun protection");
    }

    function _requireNoLusdCurvePoolTradesInCurrentBlock() internal view {
        require(lusdCurvePool.block_timestamp_last() != block.timestamp, "frontrun protection");
    }

    function _validateTradeData(bytes memory _tradeData) internal pure returns (address _stableToken, uint24 _wethToStableTokenFee, bool _useCurveForStableTokenToLusd) {
        (_stableToken, _wethToStableTokenFee, _useCurveForStableTokenToLusd) = abi.decode(_tradeData, (address, uint24, bool));
        require(_stableToken == address(lusdToken) || _stableToken == address(usdcToken) || _stableToken == address(daiToken), "invalid trade data");
        if (_stableToken == address(lusdToken)) {
            require(_wethToStableTokenFee == 3000 && _useCurveForStableTokenToLusd == false, "invalid trade data");
        } else {
            require(_wethToStableTokenFee == 500 || _wethToStableTokenFee == 3000, "invalid trade data");
        }
    }

    receive() external payable {}
}
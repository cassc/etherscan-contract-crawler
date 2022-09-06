pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IXLPToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/// @dev interface of the frax gauge. Based on FraxUnifiedFarmTemplate.sol
/// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Staking/FraxUnifiedFarmTemplate.sol
interface IUnifiedFarm {
    // Struct for the stake
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }
    function stakeLocked(uint256 liquidity, uint256 secs) external;
    function getReward(address destination_address) external returns (uint256[] memory);
    function withdrawLocked(bytes32 kek_id, address destination_address) external;
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function stakerSetVeFXSProxy(address proxy_address) external;
    function stakerToggleMigrator(address migrator_address) external;
    function lock_time_for_max_multiplier() external view returns (uint256);
    function lock_time_min() external view returns (uint256);
    function getAllRewardTokens() external view returns (address[] memory);
    function lockedLiquidityOf(address account) external view returns (uint256);
    function lockedStakesOf(address account) external view returns (LockedStake[] memory);
}

/// @dev interface of the curve stable swap.
interface IStableSwap {
    function coins(uint256 j) external view returns (address);
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount, address destination) external returns (uint256);
    function get_dy(int128 _from, int128 _to, uint256 _from_amount) external view returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function fee() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
}

contract LiquidityOps is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IXLPToken;

    IUnifiedFarm public lpFarm;          // frax unified lp farm
    IXLPToken public xlpToken;           // stax lp receipt;
    IERC20 public lpToken;               // lp pair token

    // curve pool for (xlp, lp) pair. This is an ERC20, 
    // and gets minted/burnt when new liquidity is added/removed in the pool.
    IStableSwap public curveStableSwap;

    address public rewardsManager;
    address public feeCollector;
    address public pegDefender;
    address public operator;
    
    // applyLiquidity can be toggled to be permissionless or only callable by an operator.
    bool public operatorOnlyMode;

    // The order of curve pool tokens
    int128 public inputTokenIndex;
    int128 public staxReceiptTokenIndex;

    // How much of user LP do we add into gauge.
    // The remainder is added as liquidity into curve pool
    LockRate public lockRate;  

    struct LockRate {
        uint128 numerator;
        uint128 denominator;
    }

    FeeRate public feeRate;
    struct FeeRate {
        uint128 numerator;
        uint128 denominator;
    }

    // fxs emissions + random token extra bribe
    IERC20[] public rewardTokens;

    // The period of time (secs) to lock liquidity into the farm.
    uint256 public farmLockTime;

    // FEE_DENOMINATOR from Curve StableSwap
    uint256 internal constant CURVE_FEE_DENOMINATOR = 1e10;

    event SetLockParams(uint128 numerator, uint128 denominator);
    event SetFeeParams(uint128 numerator, uint128 denominator);
    event Locked(uint256 amountLocked);
    event LiquidityAdded(uint256 lpAmount, uint256 xlpAmount, uint256 curveTokenAmount);
    event LiquidityRemoved(uint256 lpAmount, uint256 xlpAmount, uint256 curveTokenAmount);
    event WithdrawAndReLock(bytes32 _kekId, uint256 amount);
    event RewardHarvested(address token, address to, uint256 distributionAmount, uint256 feeAmount);
    event RewardClaimed(uint256[] data);
    event SetVeFXSProxy(address proxy);
    event MigratorToggled(address migrator);
    event RewardsManagerSet(address manager);
    event FeeCollectorSet(address feeCollector);
    event TokenRecovered(address user, uint256 amount);
    event CoinExchanged(address coinSent, uint256 amountSent, uint256 amountReceived);
    event RemovedLiquidityImbalance(uint256 _amount0, uint256 _amounts1, uint256 burnAmount);
    event PegDefenderSet(address defender);
    event FarmLockTimeSet(uint256 secs);
    event OperatorOnlyModeSet(bool value);
    event OperatorSet(address operator);

    constructor(
        address _lpFarm,
        address _lpToken,
        address _xlpToken,
        address _curveStableSwap,
        address _rewardsManager,
        address _feeCollector
    ) {
        lpFarm = IUnifiedFarm(_lpFarm);
        lpToken = IERC20(_lpToken);
        xlpToken = IXLPToken(_xlpToken);

        curveStableSwap = IStableSwap(_curveStableSwap);
        (staxReceiptTokenIndex, inputTokenIndex) = curveStableSwap.coins(0) == address(xlpToken)
            ? (int128(0), int128(1))
            : (int128(1), int128(0));

        rewardsManager = _rewardsManager;
        feeCollector = _feeCollector;
        
        // Lock all liquidity in the lpFarm as a (non-zero denominator) default.
        lockRate.numerator = 100;
        lockRate.denominator = 100;

        // No fees are taken by default
        feeRate.numerator = 0;
        feeRate.denominator = 100;

        // By default, set the lock time to the max (eg 3yrs for TEMPLE/FRAX)
        farmLockTime = lpFarm.lock_time_for_max_multiplier();

        // applyLiquidity is permissionless by default.
        operatorOnlyMode = false;
    }

    function setLockParams(uint128 _numerator, uint128 _denominator) external onlyOwner {
        require(_denominator > 0 && _numerator <= _denominator, "invalid params");
        lockRate.numerator = _numerator;
        lockRate.denominator = _denominator;

        emit SetLockParams(_numerator, _denominator);
    }

    function setRewardsManager(address _manager) external onlyOwner {
        require(_manager != address(0), "invalid address");
        rewardsManager = _manager;

        emit RewardsManagerSet(_manager);
    }

    function setFeeParams(uint128 _numerator, uint128 _denominator) external onlyOwner {
        require(_denominator > 0 && _numerator <= _denominator, "invalid params");
        feeRate.numerator = _numerator;
        feeRate.denominator = _denominator;

        emit SetFeeParams(_numerator, _denominator);
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "invalid address");
        feeCollector = _feeCollector;

        emit FeeCollectorSet(_feeCollector);
    }

    function setFarmLockTime(uint256 _secs) external onlyOwner {
        require(_secs >= lpFarm.lock_time_min(), "Minimum lock time not met");
        require(_secs <= lpFarm.lock_time_for_max_multiplier(),"Trying to lock for too long");
        farmLockTime = _secs;
        emit FarmLockTimeSet(_secs);
    }

    // set lp farm in case of migration
    function setLPFarm(address _lpFarm) external onlyOwner {
        require(_lpFarm != address(0), "invalid address");
        lpFarm = IUnifiedFarm(_lpFarm);
    }

    function setRewardTokens() external {
        address[] memory tokens = lpFarm.getAllRewardTokens();
        for (uint i=0; i<tokens.length; i++) {
            rewardTokens.push(IERC20(tokens[i]));
        }
    }

    function setPegDefender(address _pegDefender) external onlyOwner {
        pegDefender = _pegDefender;
        emit PegDefenderSet(_pegDefender);
    }

    function setOperatorOnlyMode(bool _operatorOnlyMode) external onlyOwner {
        operatorOnlyMode = _operatorOnlyMode;
        emit OperatorOnlyModeSet(_operatorOnlyMode);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit OperatorSet(_operator);
    }

    function exchange(
        address _coinIn,
        uint256 _amount,
        uint256 _minAmountOut
    ) external onlyPegDefender {
        (int128 in_index, int128 out_index) = (staxReceiptTokenIndex, inputTokenIndex);

        if (_coinIn == address(xlpToken)) {
            uint256 balance = xlpToken.balanceOf(address(this));
            require(_amount <= balance, "not enough tokens");
            xlpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);
        } else if (_coinIn == address(lpToken)) {
            uint256 balance = lpToken.balanceOf(address(this));
            require(_amount <= balance, "not enough tokens");
            lpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);
            (in_index, out_index) = (inputTokenIndex, staxReceiptTokenIndex);
        } else {
            revert("unknown token");
        }

        uint256 amountReceived = curveStableSwap.exchange(in_index, out_index, _amount, _minAmountOut);

        emit CoinExchanged(_coinIn, _amount, amountReceived);
    }

    function removeLiquidityImbalance(
        uint256[2] memory _amounts,
        uint256 _maxBurnAmount
    ) external onlyPegDefender {
        require(curveStableSwap.balanceOf(address(this)) > 0, "no liquidity");
        uint256 burnAmount = curveStableSwap.remove_liquidity_imbalance(_amounts, _maxBurnAmount, address(this));

        emit RemovedLiquidityImbalance(_amounts[0], _amounts[1], burnAmount);
    }

    function lockInGauge(uint256 liquidity) private {
        lpToken.safeIncreaseAllowance(address(lpFarm), liquidity);

        // if first time lock
        IUnifiedFarm.LockedStake[] memory lockedStakes = lpFarm.lockedStakesOf(address(this));
        uint256 lockedStakesLength = lockedStakes.length;

        // we want to lock additional if lock end time not expired
        // check last lockedStake if expired
        if (lockedStakesLength == 0 || block.timestamp >= lockedStakes[lockedStakesLength - 1].ending_timestamp) {
            lpFarm.stakeLocked(liquidity, farmLockTime);
        } else {
            lpFarm.lockAdditional(lockedStakes[lockedStakesLength - 1].kek_id, liquidity);
        }
        
        emit Locked(liquidity);
    }

    /** 
      * @notice Add LP/xLP 1:1 into the curve pool
      * @dev Add same amounts of lp and xlp tokens such that the price remains about the same
             - don't apply any peg fixing here. xLP tokens are minted 1:1
      * @param _amount The amount of LP and xLP to add into the pool.
      * @param _minCurveAmountOut The minimum amount of curve liquidity tokens we expect in return.
      */
    function addLiquidity(uint256 _amount, uint256 _minCurveAmountOut) private {
        uint256[2] memory amounts = [_amount, _amount];
        
        // Mint the new xLP. same as lp amount
        xlpToken.mint(address(this), _amount);

        lpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);
        xlpToken.safeIncreaseAllowance(address(curveStableSwap), _amount);

        uint256 liquidity = curveStableSwap.add_liquidity(amounts, _minCurveAmountOut, address(this));
        emit LiquidityAdded(_amount, _amount, liquidity);
    }

    function removeLiquidity(
        uint256 _liquidity,
        uint256 _lpAmountMin,
        uint256 _xlpAmountMin
    ) external onlyPegDefender {
        uint256 balance = curveStableSwap.balanceOf(address(this));
        require(balance >= _liquidity, "not enough tokens");

        uint256 receivedXlpAmount;
        uint256 receivedLpAmount;
        if (staxReceiptTokenIndex == 0) {
            uint256[2] memory balances = curveStableSwap.remove_liquidity(_liquidity, [_xlpAmountMin, _lpAmountMin]);
            receivedXlpAmount = balances[0];
            receivedLpAmount = balances[1];
        } else {
            uint256[2] memory balances = curveStableSwap.remove_liquidity(_liquidity, [_lpAmountMin, _xlpAmountMin]);
            receivedXlpAmount = balances[1];
            receivedLpAmount = balances[0];
        }

        emit LiquidityRemoved(receivedLpAmount, receivedXlpAmount, _liquidity);
    }

    /**
      * @notice Calculate the amounts of liquidity to lock in the gauge vs add into the curve pool, based on lockRate policy.
      */
    function applyLiquidityAmounts(uint256 _liquidity) private view returns (uint256 lockAmount, uint256 addLiquidityAmount) {
        lockAmount = (_liquidity * lockRate.numerator) / lockRate.denominator;
        unchecked {
            addLiquidityAmount = _liquidity - lockAmount;
        }
    }

    /** 
      * @notice Calculates the min expected amount of curve liquditity token to receive when depositing the 
      *         current eligable amount to into the curve LP:xLP liquidity pool
      * @dev Takes into account pool liquidity slippage and fees.
      * @param _liquidity The amount of LP to apply
      * @param _modelSlippage Any extra slippage to account for, given curveStableSwap.calc_token_amount() 
               is an approximation. 1e10 precision, so 1% = 1e8.
      * @return minCurveTokenAmount Expected amount of LP tokens received 
      */ 
    function minCurveLiquidityAmountOut(uint256 _liquidity, uint256 _modelSlippage) external view returns (uint256 minCurveTokenAmount) {
        uint256 feeAndSlippage = _modelSlippage + curveStableSwap.fee();
        require(feeAndSlippage <= CURVE_FEE_DENOMINATOR, "invalid slippage");
        (, uint256 addLiquidityAmount) = applyLiquidityAmounts(_liquidity);
        
        minCurveTokenAmount = 0;
        if (addLiquidityAmount > 0) {
            uint256[2] memory amounts = [addLiquidityAmount, addLiquidityAmount];
            minCurveTokenAmount = curveStableSwap.calc_token_amount(amounts, true);
            unchecked {
                minCurveTokenAmount -= minCurveTokenAmount * feeAndSlippage / CURVE_FEE_DENOMINATOR;
            }
        }
    }

    /** 
      * @notice Apply LP held by this contract - locking into the gauge and adding to the curve liquidity pool
      * @dev The ratio of gauge vs liquidity pool is goverend by the lockRate percentage, set by policy.
      *      It is by default permissionless to call, but may be beneficial to limit how liquidity is deployed
      *      in the future (by a whitelisted operator)
      * @param _liquidity The amount of LP to apply.
      * @param _minCurveTokenAmount When adding liquidity to the pool, what is the minimum number of tokens
      *        to accept.
      */
    function applyLiquidity(uint256 _liquidity, uint256 _minCurveTokenAmount) external onlyOperator {
        require(_liquidity <= lpToken.balanceOf(address(this)), "not enough liquidity");
        (uint256 lockAmount, uint256 addLiquidityAmount) = applyLiquidityAmounts(_liquidity);

        // Policy may be set to put all in gauge, or all as new curve liquidity
        if (lockAmount > 0) {
            lockInGauge(lockAmount);
        }

        if (addLiquidityAmount > 0) {
            addLiquidity(addLiquidityAmount, _minCurveTokenAmount);
        }
    }

    // withdrawAndRelock is called to withdraw expired locks and relock into the most recent
    function withdrawAndRelock(bytes32 _oldKekId) external {
        // there may be reserve lp tokens in contract. account for those
        uint256 lpTokensBefore = lpToken.balanceOf(address(this));
        lpFarm.withdrawLocked(_oldKekId, address(this));
        uint256 lpTokensAfter = lpToken.balanceOf(address(this));
        uint256 lockAmount;
        unchecked {
            lockAmount = lpTokensAfter - lpTokensBefore;
        }

        require(lockAmount > 0, "nothing to withdraw");
        lpToken.safeIncreaseAllowance(address(lpFarm), lockAmount);

        // Re-lock into the most recent lock
        IUnifiedFarm.LockedStake[] memory lockedStakes = lpFarm.lockedStakesOf(address(this));
        uint256 lockedStakesLength = lockedStakes.length;
        // avoid locking in a stale lock position. i.e. a lock with start and endtimestamp set to 0
        // check last lockedStake if expired
        if (block.timestamp >= lockedStakes[lockedStakesLength - 1].ending_timestamp) {
            lpFarm.stakeLocked(lockAmount, farmLockTime);
        } else {
            lpFarm.lockAdditional(lockedStakes[lockedStakesLength - 1].kek_id, lockAmount);
        }

        emit WithdrawAndReLock(_oldKekId, lockAmount);
    }

    // claim reward to this contract.
    // reward manager will withdraw rewards for incentivizing xlp stakers
    function getReward() external returns (uint256[] memory data) {
        data = lpFarm.getReward(address(this));

        emit RewardClaimed(data);
    }

    // get amount to lock based on lock rate
    function _getFeeAmount(uint256 _amount) internal view returns (uint256) {
        return (_amount * feeRate.numerator) / feeRate.denominator;
    }

    // harvest rewards
    function harvestRewards() external {
        // iterate through reward tokens and transfer to rewardsManager
        for (uint i=0; i<rewardTokens.length; i++) {
            IERC20 token = rewardTokens[i];
            uint256 amount = token.balanceOf(address(this));
            uint256 feeAmount = _getFeeAmount(amount);

            if (feeAmount > 0) {
                amount -= feeAmount;
                token.safeTransfer(feeCollector, feeAmount);
            }
            if (amount > 0) {
                token.safeTransfer(rewardsManager, amount);
            }

            emit RewardHarvested(address(token), rewardsManager, amount, feeAmount);
        }
    }

    // Staker can allow a veFXS proxy (the proxy will have to toggle them first)
    function setVeFXSProxy(address _proxy) external onlyOwner {
        lpFarm.stakerSetVeFXSProxy(_proxy);

        emit SetVeFXSProxy(_proxy);
    }

    // Owner can withdraw any locked position.
    // Migration on expired locks can then happen without farm gov/owner having to pause and toggleMigrations()
    function withdrawLocked(bytes32 kek_id, address destination_address) external onlyOwner {
        // The farm emits WithdrawLocked events.
        lpFarm.withdrawLocked(kek_id, destination_address);
    }
    
    // To migrate:
    // - unified farm owner/gov sets valid migrator
    // - stakerToggleMigrator() - this func
    // - gov/owner calls toggleMigrations()
    // - migrator calls migrator_withdraw_locked(this, kek_id), which calls _withdrawLocked(staker, migrator) - sends lps to migrator
    // - migrator is assumed to be new lplocker and therefore would now own the lp tokens and can relock (stakelock) in newly upgraded gauge.
    // Staker can allow a migrator
    function stakerToggleMigrator(address _migrator) external onlyOwner {
        lpFarm.stakerToggleMigrator(_migrator);

        emit MigratorToggled(_migrator);
    }

    // recover tokens except reward tokens
    // for reward tokens use harvestRewards instead
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwnerOrPegDefender {
        for (uint i=0; i<rewardTokens.length; i++) {
            require(_token != address(rewardTokens[i]), "can't recover reward token this way");
        }

        _transferToken(IERC20(_token), _to, _amount);

        emit TokenRecovered(_to, _amount);
    }

    function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 balance = _token.balanceOf(address(this));
        require(_amount <= balance, "not enough tokens");
        _token.safeTransfer(_to, _amount);
    }

    modifier onlyPegDefender() {
        require(msg.sender == pegDefender, "not defender");
        _;
    }

    modifier onlyOwnerOrPegDefender {
        require(msg.sender == owner() || msg.sender == pegDefender, "only owner or defender");
        _;
    }

    /// @dev Either set to be permissionless, or can only be called by the operator.
    modifier onlyOperator {
        require(!operatorOnlyMode || msg.sender == operator, "not operator");
        _;
    }
}
pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/temple-frax/LiquidityOps.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/common/IMintableToken.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITranche.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol";
import "../../../interfaces/investments/frax-gauge/temple-frax/ILiquidityOps.sol";
import "../../../interfaces/external/frax/IFraxGauge.sol";

import "../../../common/access/Operators.sol";
import "../../../common/Executable.sol";
import "../../../common/CommonEventsAndErrors.sol";
import "../../../common/FractionalAmount.sol";
import "../../../liquidity-pools/CurveStableSwap.sol";

/// @notice Manage the locked LP, applying it to underlying gauges (via tranches) and exit liquidity pools
///
/// When applying liquidity:
/// 1/ A new tranche is auto-created (via a factory clone) when the `trancheSize` is hit in the current tranche
/// 2/ The new tranche base implementation can be set with `nextTrancheImplId`, where
///    the `trancheRegistry` maintains the implementations and creates new instances. 
///    Example implementations:
///      a/ Direct Tranche: We proxy directly to the gauge using STAX's vefxs proxy only
///      b/ Convex Vault Tranche: We lock using the Convex frax vaults - a jointly owned vault
///         such that we can use their veFXS proxy to get a 2x rewards boost (for a fee)
///         Using tranches allow STAX to switch that chunk of LP from using Convex's veFXS proxy to STAX's veFXS proxy.
/// 3/ Each new vault will have one single active lock - so new liquidity added to that tranche will have the same boost and expiry.
///      a/ So if we create a new tranche the lock expiry will be new (and can be longer/shorter than the first one for more/less rewards boost).
///      b/ The net APR is therefore the weighted average across each of the locks.
contract LiquidityOps is ILiquidityOps, Ownable, Operators {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;
    using CurveStableSwap for CurveStableSwap.Data;
    using FractionalAmount for FractionalAmount.Data;

    /// @notice The LP token pair used for staking in the underlying gauge
    IERC20 public immutable lpToken;

    /// @notice STAX LP receipt token
    IMintableToken public immutable xlpToken;

    /** GAUGE / LOCK SETTINGS */

    /// @notice The underlying Frax gauge that we expect to be used by any new tranches. 
    IFraxGauge public underlyingGauge; 

    /// @notice Percentage of how much user LP we add into gauge each time applyLiquidity() is called.
    ///         The remainder is added as liquidity into curve pool
    FractionalAmount.Data public lockRate;  

    /// @notice The period of time (secs) to lock liquidity into the gauge.
    /// @dev Only one active lock will be created within each tranche.
    ///      So if the lock hasn't expired - we lock additional into the existing one.
    uint256 public lockTime;

    /** TRANCHE SETTINGS */

    /// @notice Registry to create new gauge tranches.
    ITrancheRegistry public trancheRegistry;

    /// @notice The tranche registry implementation to use when a new gauge tranche needs to be created.
    uint256 public nextTrancheImplId;

    /// @notice When the current tranche has more than this amount of LP locked already,
    ///         a new tranche will be created and used for the locks
    uint256 public trancheSize;

    /// @notice The address of the current gauge tranche that's being used for new LP deposits.
    ITranche public currentTranche;

    /// @notice All known gauge tranche instsances that this liquidity ops created
    mapping(address => bool) public tranches;
    address[] public trancheList;

    /** EXIT LIQUIDITY AND DEFENSE
      * 
      * A protocol determined percentage of LP will be supplied as liquidity to a Curve v1 Stable Swap.
      * This is to allow exit liquidity for users to liquidiate by exchanging xlp->lp.
      * 
      * To help manage the defense of peg, pegDefender has access to manage the protocol owned curve liqudiity.
      */

    /// @notice Curve v1 Stable Swap (xLP:LP) is used as the pool for exit liquidity.
    CurveStableSwap.Data public curveStableSwap;

    /// @notice Whitelisted account responsible for defending the exit liqudity pool's peg
    address public pegDefender;

    /** GAUGE REWARDS AND FEES */

    /// @notice What percentage of fees does STAX retain.
    FractionalAmount.Data public feeRate;

    /// @notice Destination address for retained STAX fees.
    address public feeCollector;

    /// @notice Where rewards are sent when collected from the gauge and harvested.
    address public rewardsManager;

    /// @notice FXS emissions from the underlying gauge + any other bonus tokens.
    /// @dev Operators to set this manually.
    address[] public rewardTokens;

    event LockRateSet(uint128 numerator, uint128 denominator);
    event FeeRateSet(uint128 numerator, uint128 denominator);
    event Locked(uint256 amountLocked, bytes32 kekId);
    event WithdrawAndReLock(address indexed oldTrancheAddress, bytes32 oldKekId, address indexed newTrancheAddress, uint256 amount, bytes32 newKekId);
    event RewardHarvested(address indexed token, address indexed to, uint256 distributionAmount, uint256 feeAmount);
    event RewardsManagerSet(address indexed manager);
    event FeeCollectorSet(address indexed feeCollector);
    event PegDefenderSet(address indexed defender);
    event LockTimeSet(uint256 secs);
    event UnderlyingGaugeSet(address indexed gaugeAddress);
    event NextTrancheImplSet(uint256 implId);
    event CurrentTrancheSet(address indexed tranche);
    event TrancheRegistrySet(address indexed registry);
    event TrancheSizeSet(uint256 trancheSize);
    event RewardTokensSet(address[] tokenAddresses);
    event KnownTrancheForgotten(address indexed tranche, uint256 idx);

    error OnlyOwnerOrPegDefender(address caller);
    error OnlyPegDefender(address caller); 
    error UnexpectedGauge(address expected, address found);

    constructor(
        address _underlyingGauge,
        address _trancheRegistry,
        address _lpToken,
        address _xlpToken,
        address _curveStableSwap,
        address _rewardsManager,
        address _feeCollector,
        uint256 _trancheSize
    ) {
        underlyingGauge = IFraxGauge(_underlyingGauge);
        trancheRegistry = ITrancheRegistry(_trancheRegistry); 

        lpToken = IERC20(_lpToken);
        xlpToken = IMintableToken(_xlpToken);

        ICurveStableSwap ccs = ICurveStableSwap(_curveStableSwap);
        curveStableSwap = CurveStableSwap.Data(ccs, IERC20(ccs.coins(0)), IERC20(ccs.coins(1)));

        rewardsManager = _rewardsManager;
        feeCollector = _feeCollector;
        
        // Lock all liquidity in the underlyingGauge as a (non-zero denominator) default.
        lockRate.set(100, 100);

        // No fees are taken by default
        feeRate.set(0, 100);

        // By default, set the lock time to the max (eg 3yrs for TEMPLE/FRAX)
        lockTime = underlyingGauge.lock_time_for_max_multiplier();

        trancheSize = _trancheSize;
    }

    /// @notice Set the ratio for how much to lock in the gauge (vs apply to exit liquidity pool)
    function setLockRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        lockRate.set(_numerator, _denominator);
        emit LockRateSet(_numerator, _denominator);
    }

    /// @notice Where rewards are sent when collected from the gauge and harvested.
    function setRewardsManager(address _manager) external onlyOwner {
        if (_manager == address(0)) revert CommonEventsAndErrors.InvalidAddress(_manager);
        rewardsManager = _manager;

        emit RewardsManagerSet(_manager);
    }

    /// @notice Set the ratio of how much fees STAX retains from rewards claimed from the tranches
    function setFeeRate(uint128 _numerator, uint128 _denominator) external onlyOwner {
        feeRate.set(_numerator, _denominator);
        emit FeeRateSet(_numerator, _denominator);
    }

    /// @notice Where STAX fees are sent
    function setFeeCollector(address _feeCollector) external onlyOwner {
        if (_feeCollector == address(0)) revert CommonEventsAndErrors.InvalidAddress(_feeCollector);
        feeCollector = _feeCollector;

        emit FeeCollectorSet(_feeCollector);
    }

    /// @notice Set the expected underlying gauge that is staked into.
    /// @dev Each tranche implementation that is used should also use this same underlying gauge
    function setUnderlyingGauge(address gaugeAddress) external onlyOwner {
        if (gaugeAddress == address(0)) revert CommonEventsAndErrors.InvalidAddress(gaugeAddress);

        underlyingGauge = IFraxGauge(gaugeAddress);
        emit UnderlyingGaugeSet(gaugeAddress);
    }

    /// @notice Se the tranche registry (in case of upgrade.
    /// @dev Existing tranches will need to be added into the new registry (registry.addExistingTranche)
    ///      and then added into this liquidity ops list one by one with setCurrentTranche()
    function setTrancheRegistry(address registry) external onlyOwner {
        if (registry == address(0)) revert CommonEventsAndErrors.InvalidAddress(registry);

        trancheRegistry = ITrancheRegistry(registry);
        emit TrancheRegistrySet(registry);
    }

    /// @notice The list of all tranches this liquidity ops has been managing.
    function allTranches() external override view returns (address[] memory) {
        return trancheList;
    }

    function _addTranche(address _tranche, bool _setCurrentTranche) internal {
        // Add to the known tranches
        if (!tranches[_tranche]) {
            trancheList.push(_tranche);
        }
        tranches[_tranche] = true;

        // Set the currentTranche if required
        if (_setCurrentTranche) {
            currentTranche = ITranche(_tranche);
            emit CurrentTrancheSet(_tranche);
        }
    }

    function _createTranche(uint256 _implId, bool _setCurrentTranche) internal returns (address tranche, address underlyingGaugeAddress, address stakingToken) {
        (tranche, underlyingGaugeAddress, stakingToken) = trancheRegistry.createTranche(_implId);
        
        if (underlyingGaugeAddress != address(underlyingGauge)) revert UnexpectedGauge(address(underlyingGauge), underlyingGaugeAddress);
        if (stakingToken != address(lpToken)) revert CommonEventsAndErrors.InvalidToken(address(stakingToken));

        _addTranche(tranche, _setCurrentTranche);
    }

    /// @notice Manually create a new gauge tranche for future use (or in the case of migration).
    /// @dev Once created, the new tranche can be selected for use with `setCurrentTranche()`
    function createTranche(uint256 _implId) external onlyOwnerOrOperators returns (address, address, address) {
        return _createTranche(_implId, false);
    }

    /// @notice Set the gauge tranche to use for new LP deposits.
    /// @dev This liquidity ops must be the owner of the tranche.
    /// This can be used to point to an existing tranche that was auto-created, or if a new 
    /// tranche is manually created using createTranche()
    function setCurrentTranche(address tranche) external onlyOwnerOrOperators {
        if (tranche == address(0)) revert CommonEventsAndErrors.InvalidAddress(tranche);
        if (Ownable(tranche).owner() != address(this)) revert CommonEventsAndErrors.OnlyOwner(address(this));
        _addTranche(tranche, true);
    }

    /// @notice Remove a tranche from the set of known tranches
    function forgetKnownTranche(address _tranche, uint256 _idx) external onlyOwnerOrOperators {
        if (trancheList[_idx] != _tranche) revert CommonEventsAndErrors.InvalidParam();

        delete tranches[_tranche];
        delete trancheList[_idx];

        emit KnownTrancheForgotten(_tranche, _idx);
    }

    /// @notice Set the underlying gauge lock time, used for new tranches or
    ///         new locks (if the old lock expired) in existing tranches
    function setLockTime(uint256 _secs) external onlyOwner {
        if (_secs < underlyingGauge.lock_time_min() || _secs > underlyingGauge.lock_time_for_max_multiplier()) 
            revert CommonEventsAndErrors.InvalidParam();
        lockTime = _secs;
        emit LockTimeSet(_secs);
    }

    /// @notice Set the reward tokens to get and harvest from the underlying tranches/gauges.
    /// @dev This might be just the underlying gauge tokens, but also might be others, depending on the vault type.
    function setRewardTokens(address[] calldata tokenAddresses) external onlyOwnerOrOperators {
        // Rewards can't be either the LP or xLP tokens
        for (uint256 i=0; i<tokenAddresses.length;) {
            if (
                tokenAddresses[i] == address(0) || 
                tokenAddresses[i] == address(xlpToken) || 
                tokenAddresses[i] == address(lpToken)
            ) {
                revert CommonEventsAndErrors.InvalidToken(tokenAddresses[i]);
            }
            unchecked {i++;}
        }

        rewardTokens = tokenAddresses;
        emit RewardTokensSet(tokenAddresses);
    }

    /// @notice Set the address allowed to operate peg defence.
    function setPegDefender(address _pegDefender) external onlyOwner {
        pegDefender = _pegDefender;
        emit PegDefenderSet(_pegDefender);
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice Peg Defence: Exchange xLP <--> LP
    function exchange(
        address _coinIn,
        uint256 _amount,
        uint256 _minAmountOut
    ) external onlyOwnerOrPegDefender {
        curveStableSwap.exchange(_coinIn, _amount, _minAmountOut, msg.sender); 
    }

    /// @notice Peg Defence: Remove liquidity from xLP:LP pool in imbalanced amounts
    function removeLiquidityImbalance(
        uint256[2] memory _amounts,
        uint256 _maxBurnAmount
    ) external onlyOwnerOrPegDefender {
        curveStableSwap.removeLiquidityImbalance(_amounts, _maxBurnAmount); 
    }

    /// @notice Peg Defence: Remove liquidity from xLP:LP pool in equal amounts, given an amount of liquidity
    function removeLiquidity(
        uint256 _liquidity,
        uint256 _minAmount0,
        uint256 _minAmount1
    ) external onlyOwnerOrPegDefender {
        curveStableSwap.removeLiquidity(_liquidity, _minAmount0, _minAmount1);
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
    function minCurveLiquidityAmountOut(uint256 _liquidity, uint256 _modelSlippage) external view returns (uint256) {
        (, uint256 addLiquidityAmount) = lockRate.split(_liquidity);
        return curveStableSwap.minAmountOut(addLiquidityAmount, _modelSlippage);
    }

    /** 
      * @notice Apply LP held by this contract - locking into the gauge and adding to the curve liquidity pool
      * @dev The ratio of gauge vs liquidity pool is goverend by the lockRate percentage, set by policy.
      *      It is by default permissionless to call, but may be beneficial to limit how liquidity is deployed
      *      in the future (by a whitelisted operator)
      * @param _liquidity The amount of LP to apply.
      * @param _minCurveTokenAmount When adding liquidity to the pool, what is the minimum number of tokens
      *        to accept.
      * @param _tranche The tranche to apply the liquidity into
      */
    function _applyLiquidity(uint256 _liquidity, uint256 _minCurveTokenAmount, ITranche _tranche) internal {
        uint256 balance = lpToken.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientBalance(address(lpToken), _liquidity, balance);
        (uint256 lockAmount, uint256 addLiquidityAmount) = lockRate.split(_liquidity);

        // Function is protected if we're adding LP into the pool, because we need to ensure _minCurveTokenAmount
        // is set correctly.
        if (addLiquidityAmount > 0 && msg.sender != owner() && !operators[msg.sender]) revert CommonEventsAndErrors.OnlyOwnerOrOperators(msg.sender);

        // Policy may be set to put all in gauge, or all as new curve liquidity
        if (lockAmount > 0) {
            lpToken.safeTransfer(address(_tranche), lockAmount);
            bytes32 kekId = _tranche.stake(lockAmount, lockTime);
            emit Locked(lockAmount, kekId);
        }

        if (addLiquidityAmount > 0) {
            xlpToken.mint(address(this), addLiquidityAmount);
            curveStableSwap.addLiquidity(addLiquidityAmount, _minCurveTokenAmount);
        }
    }

    /// @notice Set the tranche registry implementation to use when a new gauge tranche needs to be created.
    function setNextTrancheImplId(uint256 implId) external onlyOwnerOrOperators {
        // Cannot set a tranche implementation which is disabled / closed for staking
        ITrancheRegistry.ImplementationDetails memory implDetails = trancheRegistry.implDetails(implId);
        if (implDetails.disabled || implDetails.closedForStaking) revert ITrancheRegistry.InvalidTrancheImpl(implId);

        nextTrancheImplId = implId;
        emit NextTrancheImplSet(implId);
    }

    /// @notice Set the tranche size - when new LP is applied, if the current tranche is larger than
    ///         this size, then a new tranche will be created
    function setTrancheSize(uint256 _trancheSize) external onlyOwnerOrOperators {
        if (_trancheSize == 0) revert CommonEventsAndErrors.InvalidParam();

        trancheSize = _trancheSize;
        emit TrancheSizeSet(_trancheSize);
    }

    function _newTrancheRequired() internal view returns (bool) {
        return (
            address(currentTranche) == address(0) ||
            !currentTranche.willAcceptLock(trancheSize)
        );
    }

    /// @notice Apply any accrued LP to the underlying tranche->gauge, and exit liquidity pool
    /// @dev Actual splits and how the liqudity is applied is according to contract settings, eg `lockRate`
    function applyLiquidity(uint256 _liquidity, uint256 _minCurveTokenAmount) external {
        // If required, update/create the handle to the current gauge tranche to use.
        if (_newTrancheRequired()) {
            _createTranche(nextTrancheImplId, true);
        }

        _applyLiquidity(_liquidity, _minCurveTokenAmount, currentTranche);
    }

    /// @notice Apply liquidity in a specific tranche address.
    /// @dev This tranche must exist in the registry and be active.
    function applyLiquidityInTranche(uint256 _liquidity, uint256 _minCurveTokenAmount, address _trancheAddress) external {
        if (!tranches[_trancheAddress]) revert ITrancheRegistry.UnknownTranche(_trancheAddress);
        
        _applyLiquidity(_liquidity, _minCurveTokenAmount, ITranche(_trancheAddress));
    }

    /// @notice Withdraw from an expired lock, and relock into the most recent.
    /// @dev If the originating tranche is still active, create a new lock in that tranche
    ///      Otherwise apply into the currently active tranche's lock.
    function withdrawAndRelock(address _trancheAddress, bytes32 _oldKekId) external onlyOwnerOrOperators {
        if (!tranches[_trancheAddress]) revert ITrancheRegistry.UnknownTranche(_trancheAddress);

        // Withdraw from the old tranche, depositing the LP dircetly into the new tranche
        // As long as the old tranche is still active, re-use it.
        // Otherwise use the most current tranche
        // (which still might need creating/updating to a new tranche - based on volume/etc)
        ITranche newTranche = ITranche(_trancheAddress);
        if (newTranche.disabled()) {
            if (_newTrancheRequired()) {
                _createTranche(nextTrancheImplId, true);
            }
            newTranche = currentTranche;
        }
        uint256 withdrawnAmount = ITranche(_trancheAddress).withdraw(_oldKekId, address(newTranche));

        if (withdrawnAmount > 0) {
            // Re-lock - the LP was already transferred to the tranche.
            bytes32 newKekId = newTranche.stake(withdrawnAmount, lockTime);
            emit WithdrawAndReLock(_trancheAddress, _oldKekId, address(newTranche), withdrawnAmount, newKekId);
        }
    }

    /// @notice Pull the rewards from each of the selected tranches.
    /// @dev The caller can first get the list of active tranches off-chain using `trancheList`, 
    ///      and filter to active/split accordingly.
    function getRewards(address[] calldata _tranches) external override {
        for (uint256 i=0; i<_tranches.length;) {
            if (!tranches[_tranches[i]]) revert ITrancheRegistry.UnknownTranche(_tranches[i]);

            address trancheAddress = _tranches[i];
            ITranche(trancheAddress).getRewards(rewardTokens);
            unchecked { ++i; }    
        }
    }

    /// @notice Harvest rewards - take a cut of fees and send the remaining rewards to the `rewardsManager`
    function harvestRewards() external override {
        // Iterate through reward tokens and transfer to rewardsManager
        for (uint i=0; i<rewardTokens.length;) {
            address token = rewardTokens[i];
            (uint256 feeAmount, uint256 rewardAmount) = feeRate.split(IERC20(token).balanceOf(address(this)));

            if (feeAmount > 0) {
                IERC20(token).safeTransfer(feeCollector, feeAmount);
            }
            if (rewardAmount > 0) {
                IERC20(token).safeTransfer(rewardsManager, rewardAmount);
            }

            emit RewardHarvested(address(token), rewardsManager, rewardAmount, feeAmount);
            unchecked { i++; }
        }
    }

    /// @notice Set the underlying staker in a tranche to use a particular veFXS proxy for extra reward boost
    /// @dev The proxy will have to toggle them first.
    function setVeFXSProxyForTranche(address trancheAddress, address proxy) external onlyOwner {
        ITranche(trancheAddress).setVeFXSProxy(proxy);
    }

    /// @notice Owner can withdraw any locked position.
    /// @dev Migration on expired locks can then happen without farm gov/owner having to pause and toggleMigrations()
    function withdraw(address trancheAddress, bytes32 kek_id, address destination_address) external onlyOwnerOrOperators returns (uint256) {
        if (!tranches[trancheAddress]) revert ITrancheRegistry.UnknownTranche(trancheAddress);
        return ITranche(trancheAddress).withdraw(kek_id, destination_address);
    }
    
    // To migrate:
    // - unified farm owner/gov sets valid migrator
    // - stakerToggleMigrator() - this func
    // - gov/owner calls toggleMigrations()
    // - migrator calls migrator_withdraw_locked(this, kek_id), which calls _withdrawLocked(staker, migrator) - sends lps to migrator
    // - migrator is assumed to be new lplocker and therefore would now own the lp tokens and can relock (stakelock) in newly upgraded gauge.
    /// @notice An underlying staker in a tranche can allow a migrator
    function stakerToggleMigratorForTranche(address trancheAddress, address _migrator) external onlyOwner {
        ITranche(trancheAddress).toggleMigrator(_migrator);
    }

    /// @notice recover tokens except reward tokens
    /// @dev for reward tokens use harvestRewards instead
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwnerOrPegDefender {
        for (uint i=0; i<rewardTokens.length;) {
            if (_token == rewardTokens[i]) revert CommonEventsAndErrors.InvalidToken(_token);
            unchecked { i++; }
        }

        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /**
      * @notice execute arbitrary functions
      * @dev Operators and owners are allowed to execute
      * In LiquidityOps case, this is useful in case we need to operate on the underlying Tranches,
      * since LiquidityOps is the owner of these factory created tranches.
      * eg to update the owner (new LiquidityOps version), recover tokens, etc
      */
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwnerOrOperators returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

    modifier onlyOwnerOrOperators() {
        if (msg.sender != owner() && !operators[msg.sender]) revert CommonEventsAndErrors.OnlyOwnerOrOperators(msg.sender);
        _;
    }

    modifier onlyOwnerOrPegDefender {
        if (msg.sender != owner() && msg.sender != pegDefender) revert OnlyOwnerOrPegDefender(msg.sender);
        _;
    }

}
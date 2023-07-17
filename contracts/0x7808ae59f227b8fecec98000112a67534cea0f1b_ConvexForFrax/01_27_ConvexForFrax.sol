// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/convex/IConvexForFrax.sol";
import "../../strategies/curve/CurveBase.sol";

/**
 * @title Convex for Frax strategy
 * @dev This strategy only supports Curve deposits
 */
contract ConvexForFrax is CurveBase {
    using SafeERC20 for IERC20;

    IVaultRegistry public constant VAULT_REGISTRY = IVaultRegistry(0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa);
    IConvexFraxPoolRegistry public constant POOL_REGISTRY =
        IConvexFraxPoolRegistry(0x41a5881c17185383e19Df6FA4EC158a6F4851A69);
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

    /// @notice Frax Staking contract
    IFraxFarmERC20 public immutable fraxStaking;

    /// @notice Convex vault to interact with FRAX staking
    IStakingProxyConvex public immutable vault;

    /// @notice Convex Rewards contract
    IMultiReward public immutable rewards;

    /// @notice FRAX staking period
    /// @dev Uses the `lock_time_min` by default. Use `updateLockPeriod` to update it if needed.
    uint256 public lockPeriod;

    /// @notice Staking position ID
    bytes32 public kekId;

    /// @notice Next time where the withdraw will be available
    uint256 public unlockTime;

    /// @notice Emitted when `unlockTime` is updated
    event UnlockTimeUpdated(uint256 oldUnlockTime, uint256 newUnlockTime);

    constructor(
        address pool_,
        address crvPool_,
        PoolType curvePoolType_,
        address depositZap_,
        address crvToken_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        uint256 collateralIdx_,
        uint256 convexPoolId_,
        string memory name_
    )
        CurveBase(
            pool_,
            crvPool_,
            curvePoolType_,
            depositZap_,
            crvToken_,
            crvSlippage_,
            masterOracle_,
            swapper_,
            collateralIdx_,
            name_
        )
    {
        (, address _stakingAddress, , address _reward, ) = POOL_REGISTRY.poolInfo(convexPoolId_);
        rewards = IMultiReward(_reward);
        vault = IStakingProxyConvex(VAULT_REGISTRY.createVault(convexPoolId_));
        require(vault.curveLpToken() == address(crvLp), "incorrect-lp-token");
        fraxStaking = IFraxFarmERC20(_stakingAddress);
        lockPeriod = fraxStaking.lock_time_min();
        rewardTokens = _getRewardTokens();
    }

    function lpBalanceStaked() public view override returns (uint256 _total) {
        // Note: No need to specify which position here because we'll always have one open position at the same time
        // because of the open position is deleted when `vault.withdrawLockedAndUnwrap(kekId)` is called
        _total = fraxStaking.lockedLiquidityOf(address(vault));
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        crvLp.safeApprove(address(vault), amount_);
    }

    /// @dev Return values are not being used hence returning 0
    function _claimRewards() internal override returns (address, uint256) {
        // solhint-disable-next-line no-empty-blocks
        try vault.getReward() {} catch {
            // It may fail if reward collection is paused on FRAX side
            // See more: https://github.com/convex-eth/frax-cvx-platform/blob/01855f4f82729b49cbed0b5fab37bdefe9fdb736/contracts/contracts/StakingProxyConvex.sol#L222-L225
            vault.getReward(false);
        }
        return (address(0), 0);
    }

    /// @notice Get reward tokens
    function _getRewardTokens() internal view override returns (address[] memory _rewardTokens) {
        uint256 _extraRewardCount;
        uint256 _length = rewards.rewardTokenLength();

        for (uint256 i; i < _length; i++) {
            address _rewardToken = rewards.rewardTokens(i);
            // Some pool has CVX as extra rewards but other do not. CVX still reward token
            if (_rewardToken != CRV && _rewardToken != CVX && _rewardToken != FXS) {
                _extraRewardCount++;
            }
        }

        _rewardTokens = new address[](_extraRewardCount + 3);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        _rewardTokens[2] = FXS;
        uint256 _nextIdx = 3;

        for (uint256 i; i < _length; i++) {
            address _rewardToken = rewards.rewardTokens(i);
            // CRV and CVX already added in array
            if (_rewardToken != CRV && _rewardToken != CVX && _rewardToken != FXS) {
                _rewardTokens[_nextIdx++] = _rewardToken;
            }
        }
    }

    /**
     * @notice Stake Curve-LP token
     * @dev Stake to the current position if there is any
     */
    function _stakeAllLp() internal virtual override {
        uint256 _balance = crvLp.balanceOf(address(this));
        if (_balance > 0) {
            if (kekId != bytes32(0)) {
                // if there is an active position, lock more
                vault.lockAdditionalCurveLp(kekId, _balance);
            } else {
                // otherwise create a new position
                kekId = vault.stakeLockedCurveLp(_balance, lockPeriod);
                unlockTime = block.timestamp + lockPeriod;
            }
        }
    }

    /**
     * @notice Unstake all LPs
     * @dev This function is called by `_beforeMigration()` hook
     * @dev `withdrawLockedAndUnwrap` destroys current position
     * Should claim rewards that will be swept later
     */
    function _unstakeAllLp() internal override {
        require(block.timestamp >= unlockTime, "unlock-time-didnt-pass");
        vault.withdrawLockedAndUnwrap(kekId);
        kekId = 0x0;
    }

    /**
     * @notice Unstake LPs
     * @dev Unstake all because Convex-FRAX doesn't support partial unlocks
     */
    function _unstakeLp(uint256 _amount) internal override {
        if (_amount > 0) {
            _unstakeAllLp();
        }
    }

    /// @notice Update `lockPeriod` param
    /// @dev To be used if the `lock_time_min` value changes or we want to increase it
    function updateLockPeriod(uint256 newLockPeriod_) external onlyGovernor {
        require(newLockPeriod_ >= fraxStaking.lock_time_min(), "period-lt-min");
        emit UnlockTimeUpdated(lockPeriod, newLockPeriod_);
        lockPeriod = newLockPeriod_;
    }
}
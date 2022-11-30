// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/SafeCast.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/curve/IDeposit.sol";
import "../../interfaces/curve/IDepositZap.sol";
import "../../interfaces/curve/IStableSwap.sol";
import "../../interfaces/curve/ILiquidityGauge.sol";
import "../../interfaces/curve/ITokenMinter.sol";
import "../../interfaces/curve/IMetapoolFactory.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../../interfaces/one-oracle/IMasterOracle.sol";
import "../Strategy.sol";

/// @title This strategy will deposit collateral token in a Curve Pool and earn interest.
// solhint-disable no-empty-blocks
contract Curve is Strategy {
    using SafeERC20 for IERC20;

    enum PoolType {
        PLAIN_2_POOL,
        PLAIN_3_POOL,
        PLAIN_4_POOL,
        LENDING_2_POOL,
        LENDING_3_POOL,
        LENDING_4_POOL,
        META_3_POOL,
        META_4_POOL
    }

    string public constant VERSION = "5.0.0";
    uint256 internal constant MAX_BPS = 10_000;
    ITokenMinter public constant CRV_MINTER = ITokenMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0); // This contract only exists on mainnet
    IAddressProvider public constant ADDRESS_PROVIDER = IAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383); // Same address to all chains
    uint256 private constant FACTORY_ADDRESS_ID = 3;

    address public immutable CRV;
    IERC20 public immutable crvLp; // Note: Same as `receiptToken` but using this in order to save gas since it's `immutable` and `receiptToken` isn't
    address public immutable crvPool;
    ILiquidityGaugeV2 public immutable crvGauge;
    uint256 public immutable collateralIdx;
    address internal immutable depositZap;
    PoolType public immutable curvePoolType;
    bool private immutable isFactoryPool;

    string public NAME;
    uint256 public crvSlippage;
    IMasterOracle public masterOracle;
    address[] public rewardTokens;

    event CrvSlippageUpdated(uint256 oldCrvSlippage, uint256 newCrvSlippage);
    event MasterOracleUpdated(IMasterOracle oldMasterOracle, IMasterOracle newMasterOracle);

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
        string memory name_
    ) Strategy(pool_, swapper_, address(0)) {
        require(crvToken_ != address(0), "crv-token-is-null");

        address _crvGauge;
        IRegistry _registry = IRegistry(ADDRESS_PROVIDER.get_registry());
        address _crvLp = _registry.get_lp_token(crvPool_);

        if (_crvLp != address(0)) {
            // Get data from Registry contract
            require(collateralIdx_ < _registry.get_n_coins(crvPool_)[1], "invalid-collateral");
            require(
                _registry.get_underlying_coins(crvPool_)[collateralIdx_] == address(collateralToken),
                "collateral-mismatch"
            );
            _crvGauge = _registry.get_gauges(crvPool_)[0];
        } else {
            // Get data from Factory contract
            IMetapoolFactory _factory = IMetapoolFactory(ADDRESS_PROVIDER.get_address(FACTORY_ADDRESS_ID));

            if (_factory.is_meta(crvPool_)) {
                require(collateralIdx_ < _factory.get_meta_n_coins(crvPool_)[1], "invalid-collateral");
                require(
                    _factory.get_underlying_coins(crvPool_)[collateralIdx_] == address(collateralToken),
                    "collateral-mismatch"
                );
            } else {
                require(collateralIdx_ < _factory.get_n_coins(crvPool_), "invalid-collateral");
                require(
                    _factory.get_coins(crvPool_)[collateralIdx_] == address(collateralToken),
                    "collateral-mismatch"
                );
            }
            _crvLp = crvPool_;
            _crvGauge = _factory.get_gauge(crvPool_);
        }

        require(crvPool_ != address(0), "pool-is-null");
        require(_crvLp != address(0), "lp-is-null");
        require(_crvGauge != address(0), "gauge-is-null");

        CRV = crvToken_;
        crvPool = crvPool_;
        crvLp = IERC20(_crvLp);
        crvGauge = ILiquidityGaugeV2(_crvGauge);
        crvSlippage = crvSlippage_;
        receiptToken = _crvLp;
        collateralIdx = collateralIdx_;
        curvePoolType = curvePoolType_;
        isFactoryPool = _crvLp == crvPool_;
        depositZap = depositZap_;
        masterOracle = IMasterOracle(masterOracle_);
        rewardTokens.push(crvToken_);
        NAME = name_;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address token_) public view override returns (bool) {
        return token_ == address(crvLp) || token_ == address(collateralToken);
    }

    // Gets LP value not staked in gauge
    function lpBalanceHere() public view virtual returns (uint256 _lpHere) {
        _lpHere = crvLp.balanceOf(address(this));
    }

    function lpBalanceHereAndStaked() public view virtual returns (uint256 _lpHereAndStaked) {
        _lpHereAndStaked = crvLp.balanceOf(address(this)) + lpBalanceStaked();
    }

    function lpBalanceStaked() public view virtual returns (uint256 _lpStaked) {
        _lpStaked = crvGauge.balanceOf(address(this));
    }

    /// @notice Returns collateral balance + collateral deposited to curve
    function tvl() external view override returns (uint256) {
        return
            collateralToken.balanceOf(address(this)) +
            _quoteLpToCoin(lpBalanceHereAndStaked(), SafeCast.toInt128(int256(collateralIdx)));
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);

        address _swapper = address(swapper);

        collateralToken.safeApprove(crvPool, amount_);
        collateralToken.safeApprove(_swapper, amount_);

        uint256 _rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < _rewardTokensLength; ++i) {
            IERC20(rewardTokens[i]).safeApprove(_swapper, amount_);
        }
        crvLp.safeApprove(address(crvGauge), amount_);

        if (depositZap != address(0)) {
            collateralToken.safeApprove(depositZap, amount_);
            crvLp.safeApprove(depositZap, amount_);
        }
    }

    /// @notice Unstake LP tokens in order to transfer to the new strategy
    function _beforeMigration(address newStrategy_) internal override {
        require(IStrategy(newStrategy_).collateral() == address(collateralToken), "wrong-collateral-token");
        require(IStrategy(newStrategy_).token() == address(crvLp), "wrong-receipt-token");
        _unstakeAllLp();
    }

    function _calculateAmountOutMin(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOutMin) {
        _amountOutMin = (masterOracle.quote(tokenIn_, tokenOut_, amountIn_) * (MAX_BPS - crvSlippage)) / MAX_BPS;
    }

    function _claimRewards() internal virtual {
        if (block.chainid == 1) {
            // Side-chains don't have minter contract
            CRV_MINTER.mint(address(crvGauge));
        }
        try crvGauge.claim_rewards() {} catch {
            // This call may fail in some scenarios
            // e.g. 3Crv gauge doesn't have such function
        }
    }

    /**
     * @notice Curve pool may have more than one reward token. Child contract should override _claimRewards
     */
    function _claimRewardsAndConvertTo(address tokenOut_) internal virtual {
        _claimRewards();
        uint256 _rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < _rewardTokensLength; ++i) {
            address _rewardToken = rewardTokens[i];
            uint256 _amountIn = IERC20(_rewardToken).balanceOf(address(this));
            if (_amountIn > 0) {
                try swapper.swapExactInput(_rewardToken, tokenOut_, _amountIn, 1, address(this)) {} catch {
                    // Note: It may fail under some conditions
                    // For instance: 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT'
                }
            }
        }
    }

    function _deposit() internal {
        _depositToCurve(collateralToken.balanceOf(address(this)));
        _stakeAllLp();
    }

    function _depositTo2PlainPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[2] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        IStableSwap2x(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_);
    }

    function _depositTo2LendingPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[2] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        // Note: Using use_underlying = true to deposit underlying instead of IB token
        IStableSwap2xUnderlying(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_, true);
    }

    function _depositTo3PlainPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[3] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        IStableSwap3x(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_);
    }

    function _depositTo3LendingPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[3] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        // Note: Using use_underlying = true to deposit underlying instead of IB token
        IStableSwap3xUnderlying(crvPool).add_liquidity(_depositAmounts, lpAmountOutMin_, true);
    }

    function _depositTo4PlainOrMetaPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[4] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        IDeposit4x(depositZap).add_liquidity(_depositAmounts, lpAmountOutMin_);
    }

    function _depositTo4FactoryMetaPool(uint256 coinAmountIn_, uint256 lpAmountOutMin_) private {
        uint256[4] memory _depositAmounts;
        _depositAmounts[collateralIdx] = coinAmountIn_;
        // Note: The function below won't return a reason when reverting due to slippage
        IDepositZap4x(depositZap).add_liquidity(address(crvPool), _depositAmounts, lpAmountOutMin_);
    }

    function _depositToCurve(uint256 coinAmountIn_) private {
        if (coinAmountIn_ == 0) {
            return;
        }

        uint256 _lpAmountOutMin = _calculateAmountOutMin(address(collateralToken), address(crvLp), coinAmountIn_);

        if (curvePoolType == PoolType.PLAIN_2_POOL) {
            return _depositTo2PlainPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.LENDING_2_POOL) {
            return _depositTo2LendingPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.PLAIN_3_POOL) {
            return _depositTo3PlainPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.LENDING_3_POOL) {
            return _depositTo3LendingPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.PLAIN_4_POOL) {
            return _depositTo4PlainOrMetaPool(coinAmountIn_, _lpAmountOutMin);
        }
        if (curvePoolType == PoolType.META_4_POOL) {
            if (isFactoryPool) {
                return _depositTo4FactoryMetaPool(coinAmountIn_, _lpAmountOutMin);
            }
            return _depositTo4PlainOrMetaPool(coinAmountIn_, _lpAmountOutMin);
        }

        revert("deposit-to-curve-failed");
    }

    function _generateReport()
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _strategyDebt = IVesperPool(pool).totalDebtOf(address(this));

        _claimRewardsAndConvertTo(address(collateralToken));

        int128 _i = SafeCast.toInt128(int256(collateralIdx));
        uint256 _lpHere = lpBalanceHere();
        uint256 _totalLp = _lpHere + lpBalanceStaked();
        uint256 _collateralInCurve = _quoteLpToCoin(_totalLp, _i);
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + _collateralInCurve;

        if (_totalCollateral > _strategyDebt) {
            _profit = _totalCollateral - _strategyDebt;
        } else {
            _loss = _strategyDebt - _totalCollateral;
        }

        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_profitAndExcessDebt > _collateralHere) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _collateralInCurve);
            if (_totalAmountToWithdraw > 0) {
                uint256 _lpToBurn = Math.min((_totalAmountToWithdraw * _totalLp) / _collateralInCurve, _totalLp);

                if (_lpToBurn > 0) {
                    if (_lpToBurn > _lpHere) {
                        _unstakeLp(_lpToBurn - _lpHere);
                    }

                    _withdrawFromCurve(_lpToBurn, _i);

                    _collateralHere = collateralToken.balanceOf(address(this));
                }
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
    }

    function _quoteLpToCoin(uint256 amountIn_, int128 toIdx_) private view returns (uint256 _amountOut) {
        if (amountIn_ == 0) {
            return 0;
        }

        if (curvePoolType == PoolType.PLAIN_4_POOL) {
            return IDeposit4x(depositZap).calc_withdraw_one_coin(amountIn_, toIdx_);
        }
        if (curvePoolType == PoolType.META_4_POOL) {
            if (isFactoryPool) {
                return IDepositZap4x(depositZap).calc_withdraw_one_coin(address(crvLp), amountIn_, toIdx_);
            }
            return IDeposit4x(depositZap).calc_withdraw_one_coin(amountIn_, toIdx_);
        }

        return IStableSwap(crvPool).calc_withdraw_one_coin(amountIn_, toIdx_);
    }

    function _rebalance()
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        (_profit, _loss, _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    // Requires that gauge has approval for lp token
    function _stakeAllLp() internal virtual {
        uint256 _balance = crvLp.balanceOf(address(this));
        if (_balance > 0) {
            crvGauge.deposit(_balance);
        }
    }

    function _unstakeAllLp() internal virtual {
        _unstakeLp(crvGauge.balanceOf(address(this)));
    }

    function _unstakeLp(uint256 amount_) internal virtual {
        if (amount_ > 0) {
            crvGauge.withdraw(amount_);
        }
    }

    function _withdrawFromPlainPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        IStableSwap(crvPool).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_);
    }

    function _withdrawFrom2LendingPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        // Note: Using use_underlying = true to withdraw underlying instead of IB token
        IStableSwap2xUnderlying(crvPool).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_, true);
    }

    function _withdrawFrom3LendingPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        // Note: Using use_underlying = true to withdraw underlying instead of IB token
        IStableSwap3xUnderlying(crvPool).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_, true);
    }

    function _withdrawFrom4PlainOrMetaPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        IDeposit4x(depositZap).remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_);
    }

    function _withdrawFrom4FactoryMetaPool(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) private {
        // Note: The function below won't return a reason when reverting due to slippage
        IDepositZap4x(depositZap).remove_liquidity_one_coin(address(crvLp), lpAmount_, i_, minAmountOut_);
    }

    function _withdrawFromCurve(uint256 lpToBurn_, int128 coinIdx_) internal {
        if (lpToBurn_ == 0) {
            return;
        }

        uint256 _minCoinAmountOut = _calculateAmountOutMin(address(crvLp), address(collateralToken), lpToBurn_);

        if (curvePoolType == PoolType.PLAIN_2_POOL || curvePoolType == PoolType.PLAIN_3_POOL) {
            return _withdrawFromPlainPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.LENDING_2_POOL) {
            return _withdrawFrom2LendingPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.LENDING_3_POOL) {
            return _withdrawFrom3LendingPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.PLAIN_4_POOL) {
            return _withdrawFrom4PlainOrMetaPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }
        if (curvePoolType == PoolType.META_4_POOL) {
            if (isFactoryPool) {
                return _withdrawFrom4FactoryMetaPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
            }
            return _withdrawFrom4PlainOrMetaPool(lpToBurn_, _minCoinAmountOut, coinIdx_);
        }

        revert("withdraw-from-curve-failed");
    }

    function _withdrawHere(uint256 coinAmountOut_) internal override {
        int128 _i = SafeCast.toInt128(int256(collateralIdx));

        uint256 _lpHere = lpBalanceHere();
        uint256 _totalLp = _lpHere + lpBalanceStaked();
        uint256 _lpToBurn = Math.min((coinAmountOut_ * _totalLp) / _quoteLpToCoin(_totalLp, _i), _totalLp);

        if (_lpToBurn == 0) return;

        if (_lpToBurn > _lpHere) {
            _unstakeLp(_lpToBurn - _lpHere);
        }

        _withdrawFromCurve(_lpToBurn, _i);
    }

    /// @dev Rewards token in gauge can be updated any time. Governor can set reward tokens
    /// Different version of gauge has different method to read reward tokens better governor set it
    function setRewardTokens(address[] memory rewardTokens_) external virtual onlyGovernor {
        rewardTokens = rewardTokens_;
        address _receiptToken = receiptToken;
        uint256 _rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < _rewardTokensLength; ++i) {
            require(
                rewardTokens_[i] != _receiptToken &&
                    rewardTokens_[i] != address(collateralToken) &&
                    rewardTokens_[i] != pool &&
                    rewardTokens_[i] != address(crvLp),
                "Invalid reward token"
            );
        }
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }

    function updateCrvSlippage(uint256 newCrvSlippage_) external onlyGovernor {
        require(newCrvSlippage_ < MAX_BPS, "invalid-slippage-value");
        emit CrvSlippageUpdated(crvSlippage, newCrvSlippage_);
        crvSlippage = newCrvSlippage_;
    }

    function updateMasterOracle(IMasterOracle newMasterOracle_) external onlyGovernor {
        emit MasterOracleUpdated(masterOracle, newMasterOracle_);
        masterOracle = newMasterOracle_;
    }
}
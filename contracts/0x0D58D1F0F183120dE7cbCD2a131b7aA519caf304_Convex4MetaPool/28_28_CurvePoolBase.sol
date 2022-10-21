// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/SafeCast.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
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
abstract contract CurvePoolBase is Strategy {
    using SafeERC20 for IERC20;

    string public constant VERSION = "5.0.0";

    uint256 internal constant MAX_BPS = 10_000;

    ITokenMinter public constant CRV_MINTER = ITokenMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0); // This contract only exists on mainnet
    IAddressProvider public constant ADDRESS_PROVIDER = IAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383); // Same address to all chains
    uint256 private constant FACTORY_ADDRESS_ID = 3;

    // Note: Same as `receiptToken` but using this in order to save gas since it's `immutable` and `receiptToken` isn't
    IERC20 public immutable crvLp;
    address public immutable crvPool;
    ILiquidityGaugeV2 public immutable crvGauge;

    // solhint-disable-next-line var-name-mixedcase
    address public CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52; // Mainnet
    // solhint-disable-next-line var-name-mixedcase
    string public NAME;

    uint256 public immutable collateralIdx;
    uint256 public crvSlippage;
    IMasterOracle public masterOracle;

    address[] public rewardTokens;

    event CrvSlippageUpdated(uint256 oldCrvSlippage, uint256 newCrvSlippage);
    event MasterOracleUpdated(IMasterOracle oldMasterOracle, IMasterOracle newMasterOracle);

    constructor(
        address pool_,
        address crvPool_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        uint256 collateralIdx_,
        string memory name_
    ) Strategy(pool_, swapper_, address(0)) {
        if (block.chainid == 43114) {
            // Avalanche
            CRV = 0x47536F17F4fF30e64A96a7555826b8f9e66ec468;
        } else if (block.chainid == 137) {
            // Polygon
            CRV = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
        } else if (block.chainid == 42161) {
            // Arbitrum
            CRV = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;
        }

        address _crvLp;
        address _crvGauge;
        address _collateral;

        IRegistry _registry = IRegistry(ADDRESS_PROVIDER.get_registry());
        _crvLp = _registry.get_lp_token(crvPool_);

        bool _isFactoryPool = _crvLp == address(0);

        if (!_isFactoryPool) {
            require(collateralIdx_ < _registry.get_n_coins(crvPool_)[1], "invalid-collateral");
            _collateral = _registry.get_underlying_coins(crvPool_)[collateralIdx_];
            _crvGauge = _registry.get_gauges(crvPool_)[0]; // TODO: Check other gauges?

            // Note: The Curve's `Registry` is returning null when calling `get_gauges()` for the FRAX-USDC pool
            // See more: https://github.com/curvefi/curve-pool-registry/issues/36
            if (_crvGauge == address(0) && crvPool_ == 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2) {
                // Address get from https://curve.fi/contracts page
                _crvGauge = 0xCFc25170633581Bf896CB6CDeE170e3E3Aa59503;
            }
        } else {
            IMetapoolFactory _factory = IMetapoolFactory(ADDRESS_PROVIDER.get_address(FACTORY_ADDRESS_ID));

            if (_factory.is_meta(crvPool_)) {
                require(collateralIdx_ < _factory.get_meta_n_coins(crvPool_)[1], "invalid-collateral");
                _collateral = _factory.get_underlying_coins(crvPool_)[collateralIdx_];
            } else {
                require(collateralIdx_ < _factory.get_n_coins(crvPool_), "invalid-collateral");
                _collateral = _factory.get_coins(crvPool_)[collateralIdx_];
            }
            _crvLp = crvPool_;
            _crvGauge = _factory.get_gauge(crvPool_);
        }

        require(_collateral == address(IVesperPool(pool_).token()), "collateral-mismatch");
        require(crvPool_ != address(0), "pool-is-null");
        require(_crvLp != address(0), "lp-is-null");
        require(_crvGauge != address(0), "gauge-is-null");

        crvPool = crvPool_;
        crvLp = IERC20(_crvLp);
        crvGauge = ILiquidityGaugeV2(_crvGauge);
        crvSlippage = crvSlippage_;
        receiptToken = _crvLp;
        collateralIdx = collateralIdx_;

        NAME = name_;
        masterOracle = IMasterOracle(masterOracle_);
        rewardTokens.push(CRV);
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
    ) internal view returns (uint256 _amountOutMin) {
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

    function _depositToCurve(uint256 amount_) internal virtual;

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

                    _withdrawFromCurve(
                        _lpToBurn,
                        _calculateAmountOutMin(receiptToken, address(collateralToken), _lpToBurn),
                        _i
                    );

                    _collateralHere = collateralToken.balanceOf(address(this));
                }
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
    }

    function _quoteLpToCoin(uint256 amountIn_, int128 toIdx_) internal view virtual returns (uint256 amountOut) {
        if (amountIn_ > 0) {
            amountOut = IStableSwap(crvPool).calc_withdraw_one_coin(amountIn_, toIdx_);
        }
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

    function _withdrawFromCurve(
        uint256 lpToBurn_,
        uint256 minCoinAmountOut_,
        int128 coinIdx_
    ) internal virtual {
        IStableSwap(crvPool).remove_liquidity_one_coin(lpToBurn_, coinIdx_, minCoinAmountOut_);
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

        uint256 _coinAmountOutMin = _calculateAmountOutMin(address(crvLp), address(collateralToken), _lpToBurn);
        _withdrawFromCurve(_lpToBurn, _coinAmountOutMin, _i);
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
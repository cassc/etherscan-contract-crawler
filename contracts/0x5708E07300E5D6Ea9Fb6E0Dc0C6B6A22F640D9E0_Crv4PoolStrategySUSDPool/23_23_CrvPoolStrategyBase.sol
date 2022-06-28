// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../dependencies/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../interfaces/vesper/IVesperPool.sol";
import "../Strategy.sol";
import "./CrvBase.sol";

/// @title This strategy will deposit collateral token in a Curve Pool and earn interest.
abstract contract CrvPoolStrategyBase is CrvBase, Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "4.0.0";

    mapping(address => bool) internal reservedToken;

    uint256 public immutable collIdx;
    uint256 public usdRate;
    uint256 public usdRateTimestamp;

    address[] public coins;
    uint256[] public coinDecimals;
    address[] public rewardTokens;
    bool public depositError;

    uint256 public crvSlippage = 10; // 10000 is 100%; 10 is 0.1%
    uint256 public decimalConversionFactor; // It will be used in converting value to/from 18 decimals

    // No. of pooled tokens in the Pool
    uint256 internal immutable n;
    event UpdatedCrvSlippage(uint256 oldCrvSlippage, uint256 newCrvSlippage);

    event DepositFailed(string reason);

    constructor(
        address _pool,
        address _crvPool,
        address _crvLp,
        address _crvGauge,
        address _swapManager,
        uint256 _collateralIdx,
        uint256 _n,
        string memory _name
    )
        CrvBase(_crvPool, _crvLp, _crvGauge) // 3Pool Manager
        Strategy(_pool, _swapManager, _crvLp)
    {
        require(_collateralIdx < _n, "invalid-collateral");

        n = _n;
        reservedToken[_crvLp] = true;
        reservedToken[CRV] = true;
        collIdx = _collateralIdx;
        _init(_crvPool, _n);
        require(coins[_collateralIdx] == address(IVesperPool(_pool).token()), "collateral-mismatch");
        // Assuming token supports 18 or less decimals. _init will initialize coins array
        uint256 _decimals = IERC20Metadata(coins[_collateralIdx]).decimals();
        decimalConversionFactor = 10**(18 - _decimals);
        NAME = _name;
        rewardTokens.push(CRV);
    }

    /// @dev Rewards token in gauge can be updated any time. Governor can set reward tokens
    /// Different version of gauge has different method to read reward tokens better governor set it
    function setRewardTokens(address[] memory _rewardTokens) external virtual onlyGovernor {
        rewardTokens = _rewardTokens;
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            require(
                _rewardTokens[i] != receiptToken &&
                    _rewardTokens[i] != address(collateralToken) &&
                    _rewardTokens[i] != pool &&
                    _rewardTokens[i] != crvLp,
                "Invalid reward token"
            );
            reservedToken[_rewardTokens[i]] = true;
        }
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
        _setupOracles();
    }

    function updateCrvSlippage(uint256 _newCrvSlippage) external onlyGovernor {
        require(_newCrvSlippage < 10000, "invalid-slippage-value");
        emit UpdatedCrvSlippage(crvSlippage, _newCrvSlippage);
        crvSlippage = _newCrvSlippage;
    }

    /// @dev Claimable rewards estimated into pool's collateral value
    function estimateClaimableRewardsInCollateral() public view virtual returns (uint256 rewardAsCollateral) {
        //Total Mintable - Previously minted
        uint256 claimable =
            ILiquidityGaugeV2(crvGauge).integrate_fraction(address(this)) -
                ITokenMinter(CRV_MINTER).minted(address(this), crvGauge);
        if (claimable != 0) {
            (, rewardAsCollateral, ) = swapManager.bestOutputFixedInput(CRV, address(collateralToken), claimable);
        }
    }

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _amount) public view returns (uint256) {
        return _amount / decimalConversionFactor;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return reservedToken[_token];
    }

    /**
     * @notice Calculate total value of asset under management
     * @dev Report total value in collateral token
     */
    function totalValue() public view virtual override returns (uint256 _value) {
        _value =
            collateralToken.balanceOf(address(this)) +
            convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage)) +
            estimateClaimableRewardsInCollateral();
    }

    function _setupOracles() internal virtual override {
        _safeCreateOrUpdateOracle(CRV, WETH);
        for (uint256 i = 0; i < n; i++) {
            _safeCreateOrUpdateOracle(coins[i], WETH);
        }
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _safeCreateOrUpdateOracle(rewardTokens[i], WETH);
        }
    }

    /**
     * @dev Creates Oracle pair preventing revert if it doesn't exist in a DEX
     */
    function _safeCreateOrUpdateOracle(address _tokenA, address _tokenB) internal {
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            // solhint-disable no-empty-blocks
            try swapManager.createOrUpdateOracle(_tokenA, _tokenB, oraclePeriod, i) {
                break;
            } catch Error(
                string memory /* reason */
            ) {}
            // solhint-enable no-empty-blocks
        }
    }

    // given the rates of 3 stable coins compared with a common denominator
    // return the lowest divided by the highest
    function _getSafeUsdRate() internal returns (uint256) {
        // use a stored rate if we've looked it up recently
        if (usdRateTimestamp > block.timestamp - oraclePeriod && usdRate != 0) return usdRate;
        // otherwise, calculate a rate and store it.
        uint256 lowest;
        uint256 highest;
        for (uint256 i = 0; i < n; i++) {
            // get the rate for $1
            (uint256 rate, bool isValid) = _consultOracle(coins[i], WETH, 10**coinDecimals[i]);
            if (isValid) {
                if (lowest == 0 || rate < lowest) {
                    lowest = rate;
                }
                if (highest < rate) {
                    highest = rate;
                }
            }
        }
        // We only need to check one of them because if a single valid rate is returned,
        // highest == lowest and highest > 0 && lowest > 0
        require(lowest != 0, "no-oracle-rates");
        usdRateTimestamp = block.timestamp;
        usdRate = (lowest * 1e18) / highest;
        return usdRate;
    }

    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(crvPool), _amount);
        for (uint256 j = 0; j < swapManager.N_DEX(); j++) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                IERC20(rewardTokens[i]).safeApprove(address(swapManager.ROUTERS(j)), _amount);
            }
            collateralToken.safeApprove(address(swapManager.ROUTERS(j)), _amount);
        }
        IERC20(crvLp).safeApprove(crvGauge, _amount);
    }

    function _init(address _crvPool, uint256 _n) internal virtual {
        for (uint256 i = 0; i < _n; i++) {
            coins.push(IStableSwapUnderlying(_crvPool).coins(i));
            coinDecimals.push(IERC20Metadata(coins[i]).decimals());
        }
    }

    function _reinvest() internal override {
        depositError = false;
        uint256 amt = collateralToken.balanceOf(address(this));
        depositError = !_depositToCurve(amt);
        _stakeAllLp();
    }

    function _depositToCurve(uint256 amt) internal virtual returns (bool) {
        if (amt != 0) {
            uint256[3] memory depositAmounts;
            depositAmounts[collIdx] = amt;
            uint256 expectedOut =
                _calcAmtOutAfterSlippage(
                    IStableSwap3xUnderlying(address(crvPool)).calc_token_amount(depositAmounts, true),
                    crvSlippage
                );
            uint256 minLpAmount =
                ((amt * _getSafeUsdRate()) / crvPool.get_virtual_price()) * 10**(18 - coinDecimals[collIdx]);
            if (expectedOut > minLpAmount) minLpAmount = expectedOut;
            // solhint-disable-next-line no-empty-blocks
            try IStableSwap3xUnderlying(address(crvPool)).add_liquidity(depositAmounts, minLpAmount) {} catch Error(
                string memory reason
            ) {
                emit DepositFailed(reason);
                return false;
            }
        }
        return true;
    }

    function _withdraw(uint256 _amount) internal override {
        // This adds some gas but will save loss on exchange fees
        uint256 balanceHere = collateralToken.balanceOf(address(this));
        if (_amount > balanceHere) {
            _unstakeAndWithdrawAsCollateral(_amount - balanceHere);
        }
        collateralToken.safeTransfer(pool, _amount);
    }

    function _unstakeAndWithdrawAsCollateral(uint256 _amount) internal returns (uint256 toWithdraw) {
        if (_amount == 0) return 0;
        uint256 i = collIdx;
        (uint256 lpToWithdraw, uint256 unstakeAmt) = calcWithdrawLpAs(_amount, i);
        _unstakeLp(unstakeAmt);
        uint256 minAmtOut =
            convertFrom18(
                (lpToWithdraw * _calcAmtOutAfterSlippage(_minimumLpPrice(_getSafeUsdRate()), crvSlippage)) / 1e18
            );
        _withdrawAsFromCrvPool(lpToWithdraw, minAmtOut, i);
        toWithdraw = collateralToken.balanceOf(address(this));
        if (toWithdraw > _amount) toWithdraw = _amount;
    }

    /**
     * @notice some strategy may want to prepare before doing migration.
        Example In Maker old strategy want to give vault ownership to new strategy
     */
    function _beforeMigration(
        address /*_newStrategy*/
    ) internal override {
        _unstakeAllLp();
    }

    /**
     * @notice Curve pool may have more than one reward token. Child contract should override _claimRewards
     */
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        _claimRewards();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 _amt = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (_amt != 0) {
                uint256 _minAmtOut;
                if (swapSlippage < 10000) {
                    (uint256 _minWethOut, bool _isValid) = _consultOracle(rewardTokens[i], WETH, _amt);
                    (uint256 _minTokenOut, bool _isValidTwo) = _consultOracle(WETH, _toToken, _minWethOut);
                    require(_isValid, "stale-reward-oracle");
                    require(_isValidTwo, "stale-collateral-oracle");
                    _minAmtOut = _calcAmtOutAfterSlippage(_minTokenOut, swapSlippage);
                }
                _safeSwap(rewardTokens[i], _toToken, _amt, _minAmtOut);
            }
        }
    }

    /**
     * @notice Withdraw collateral to payback excess debt in pool.
     * @param _excessDebt Excess debt of strategy in collateral token
     * @param _extra additional amount to unstake and withdraw, in collateral token
     * @return _payback amount in collateral token. Usually it is equal to excess debt.
     */
    function _liquidate(uint256 _excessDebt, uint256 _extra) internal returns (uint256 _payback) {
        _payback = _unstakeAndWithdrawAsCollateral(_excessDebt + _extra);
        // we don't want to return a value greater than we need to
        if (_payback > _excessDebt) _payback = _excessDebt;
    }

    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
        uint256 _collateralBalance = convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage));
        if (_collateralBalance < _totalDebt) {
            _loss = _totalDebt - _collateralBalance;
        }
    }

    function _realizeGross(uint256 _totalDebt)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _toUnstake
        )
    {
        uint256 baseline = collateralToken.balanceOf(address(this));
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 newBalance = collateralToken.balanceOf(address(this));
        _profit = newBalance - baseline;

        uint256 _collateralBalance =
            baseline + convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage));
        if (_collateralBalance > _totalDebt) {
            _profit += _collateralBalance - _totalDebt;
        } else {
            _loss = _totalDebt - _collateralBalance;
        }

        if (_profit > _loss) {
            _profit = _profit - _loss;
            _loss = 0;
            if (_profit > newBalance) _toUnstake = _profit - newBalance;
        } else {
            _loss = _loss - _profit;
            _profit = 0;
        }
    }

    function _generateReport()
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));
        uint256 _toUnstake;
        (_profit, _loss, _toUnstake) = _realizeGross(_totalDebt);
        // only make call to unstake and withdraw once
        _payback = _liquidate(_excessDebt, _toUnstake);
    }

    function rebalance() external virtual override onlyKeeper {
        (uint256 _profit, uint256 _loss, uint256 _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _reinvest();
        if (!depositError) {
            uint256 _depositLoss = _realizeLoss(IVesperPool(pool).totalDebtOf(address(this)));
            IVesperPool(pool).reportLoss(_depositLoss);
        }
    }

    // Unused
    /* solhint-disable no-empty-blocks */

    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {}

    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256 _profit) {}
}
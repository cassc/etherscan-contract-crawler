// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interfaces/curve/IDepositZap.sol";
import "../CurvePoolBase.sol";

/// @title This strategy will deposit collateral token in Curve a 4Pool Metapool and earn interest.
contract Curve4FactoryMetaPool is CurvePoolBase {
    using SafeERC20 for IERC20;

    IDepositZap4x internal immutable depositZap;

    constructor(
        address pool_,
        address crvPool_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        address depositZap_,
        uint256 collateralIdx_,
        string memory name_
    ) CurvePoolBase(pool_, crvPool_, crvSlippage_, masterOracle_, swapper_, collateralIdx_, name_) {
        depositZap = IDepositZap4x(depositZap_);
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        collateralToken.safeApprove(address(depositZap), amount_);
        crvLp.safeApprove(address(depositZap), amount_);
    }

    function _depositToCurve(uint256 coinAmountIn_) internal virtual override {
        if (coinAmountIn_ > 0) {
            uint256[4] memory _depositAmounts;
            _depositAmounts[collateralIdx] = coinAmountIn_;

            uint256 _lpAmountOutMin = _calculateAmountOutMin(address(collateralToken), address(crvLp), coinAmountIn_);
            // Note: The function below won't return a reason when reverting due to slippage
            depositZap.add_liquidity(address(crvPool), _depositAmounts, _lpAmountOutMin);
        }
    }

    function _quoteLpToCoin(uint256 _lpAmount, int128 _i) internal view virtual override returns (uint256 _amountOut) {
        if (_lpAmount > 0) {
            _amountOut = depositZap.calc_withdraw_one_coin(address(crvLp), _lpAmount, _i);
        }
    }

    function _withdrawFromCurve(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) internal virtual override {
        // Note: The function below won't return a reason when reverting due to slippage
        depositZap.remove_liquidity_one_coin(address(crvLp), lpAmount_, i_, minAmountOut_);
    }
}
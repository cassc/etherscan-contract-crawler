// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interfaces/curve/IDeposit.sol";
import "../CurvePoolBase.sol";

/**
 * @title This strategy will deposit collateral token in a Curve 4Pool and earn interest.
 * @dev Both Meta and Plain 4Pools implement the same Deposit contract interface
 */
contract Curve4PlainOr4MetaPool is CurvePoolBase {
    using SafeERC20 for IERC20;

    IDeposit4x public immutable crvDeposit;

    constructor(
        address pool_,
        address crvPool_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        address crvDeposit_,
        uint256 collateralIdx_,
        string memory name_
    ) CurvePoolBase(pool_, crvPool_, crvSlippage_, masterOracle_, swapper_, collateralIdx_, name_) {
        crvDeposit = IDeposit4x(crvDeposit_);
        require(crvDeposit.token() == address(crvLp), "invalid-deposit-contract");
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        collateralToken.safeApprove(address(crvDeposit), amount_);
        crvLp.safeApprove(address(crvDeposit), amount_);
    }

    function _depositToCurve(uint256 coinAmountIn_) internal virtual override {
        if (coinAmountIn_ > 0) {
            uint256[4] memory _depositAmounts;
            _depositAmounts[collateralIdx] = coinAmountIn_;

            uint256 _lpAmountOutMin = _calculateAmountOutMin(address(collateralToken), address(crvLp), coinAmountIn_);
            crvDeposit.add_liquidity(_depositAmounts, _lpAmountOutMin);
        }
    }

    function _quoteLpToCoin(uint256 amountIn_, int128 i_) internal view virtual override returns (uint256 _amountOut) {
        if (amountIn_ > 0) {
            _amountOut = crvDeposit.calc_withdraw_one_coin(amountIn_, i_);
        }
    }

    function _withdrawFromCurve(
        uint256 lpAmount_,
        uint256 minAmountOut_,
        int128 i_
    ) internal virtual override {
        crvDeposit.remove_liquidity_one_coin(lpAmount_, i_, minAmountOut_);
    }
}
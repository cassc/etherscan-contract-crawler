// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../CurvePoolBase.sol";

// solhint-disable no-empty-blocks

/// @title This strategy will deposit collateral token in a Curve 2Pool and earn interest.
contract Curve2PlainPool is CurvePoolBase {
    constructor(
        address pool_,
        address crvPool_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        uint256 collateralIdx_,
        string memory name_
    ) CurvePoolBase(pool_, crvPool_, crvSlippage_, masterOracle_, swapper_, collateralIdx_, name_) {}

    function _depositToCurve(uint256 coinAmountIn_) internal virtual override {
        if (coinAmountIn_ > 0) {
            uint256[2] memory _depositAmounts;
            _depositAmounts[collateralIdx] = coinAmountIn_;

            uint256 _lpAmountOutMin = _calculateAmountOutMin(address(collateralToken), address(crvLp), coinAmountIn_);
            IStableSwap2x(crvPool).add_liquidity(_depositAmounts, _lpAmountOutMin);
        }
    }
}
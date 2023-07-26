pragma solidity ^0.8.10;

import "./AuraAdapterBase.sol";
import { FixedPoint } from "./utils/FixedPoint.sol";
import { IWeightedPool } from "./interfaces/IWeightedPool.sol";

contract AuraWeightedPoolAdapter is AuraAdapterBase {
    using FixedPoint for uint256;

    uint256 internal constant _MIN_INVARIANT_RATIO = 0.7e18;

    function underlyingBalance() public view override returns (uint256) {
        uint256 lpBal = auraRewardPool.balanceOf(address(this));
        if (lpBal == 0) {
            return 0;
        }
        // get pool balances
        (, uint256[] memory _balances,) = vault.getPoolTokens(poolId);
        // get normalized weights
        uint256[] memory _weights = IWeightedPool(pool).getNormalizedWeights();
        // get total supply
        uint256 lpTotalSupply = IERC20(pool).totalSupply();
        //get swap fee
        uint256 swapFeePercentage = IWeightedPool(pool).getSwapFeePercentage();

        uint256 tokenOut = _calcTokenOutGivenExactBptIn(
            _balances[tokenIndex], _weights[tokenIndex], lpBal, lpTotalSupply, swapFeePercentage
        );
        return tokenOut;
    }

    function _calcTokenOutGivenExactBptIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    )
        internal
        pure
        returns (uint256)
    {
        /**
         *
         *     // exactBPTInForTokenOut                                                                //
         *     // a = amountOut                                                                        //
         *     // b = balance                     /      /    totalBPT - bptIn       \    (1 / w)  \   //
         *     // bptIn = bptAmountIn    a = b * |  1 - | --------------------------  | ^           |  //
         *     // bpt = totalBPT                  \      \       totalBPT            /             /   //
         *     // w = weight                                                                           //
         *
         */

        // Token out, so we round down overall. The multiplication rounds down, but the power rounds up (so the base
        // rounds up). Because (totalBPT - bptIn) / totalBPT <= 1, the exponent rounds down.

        // Calculate the factor by which the invariant will decrease after burning BPTAmountIn
        uint256 invariantRatio = bptTotalSupply.sub(bptAmountIn).divUp(bptTotalSupply);
        require(invariantRatio >= _MIN_INVARIANT_RATIO, "MIN_BPT_IN_FOR_TOKEN_OUT");

        // Calculate by how much the token balance has to decrease to match invariantRatio
        uint256 balanceRatio = invariantRatio.powUp(FixedPoint.ONE.divDown(normalizedWeight));

        // Because of rounding up, balanceRatio can be greater than one. Using complement prevents reverts.
        uint256 amountOutWithoutFee = balance.mulDown(balanceRatio.complement());

        // We can now compute how much excess balance is being withdrawn as a result of the virtual swaps, which result
        // in swap fees.

        // Swap fees are typically charged on 'token in', but there is no 'token in' here, so we apply it
        // to 'token out'. This results in slightly larger price impact. Fees are rounded up.
        uint256 taxableAmount = amountOutWithoutFee.mulUp(normalizedWeight.complement());
        uint256 nonTaxableAmount = amountOutWithoutFee.sub(taxableAmount);
        uint256 taxableAmountMinusFees = taxableAmount.mulUp(swapFeePercentage.complement());

        return nonTaxableAmount.add(taxableAmountMinusFees);
    }
}
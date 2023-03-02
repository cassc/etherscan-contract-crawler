// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '../libraries/DSMath.sol';
import './PoolV2.sol';

/**
 * @title HighCovRatioFeePoolV2
 * @dev Pool with high cov ratio fee protection
 * Change log:
 * - add `gap` to prevent storage collision for future upgrades
 */
contract HighCovRatioFeePoolV2 is PoolV2 {
    using DSMath for uint256;

    uint128 public startCovRatio; // 1.5
    uint128 public endCovRatio; // 1.8

    uint256[50] private gap;

    error WOMBAT_COV_RATIO_LIMIT_EXCEEDED();

    function initialize(uint256 ampFactor_, uint256 haircutRate_) public override {
        super.initialize(ampFactor_, haircutRate_);
        startCovRatio = 15e17;
        endCovRatio = 18e17;
    }

    function setCovRatioFeeParam(uint128 startCovRatio_, uint128 endCovRatio_) external onlyOwner {
        if (startCovRatio_ < 1e18 || startCovRatio_ > endCovRatio_) revert WOMBAT_INVALID_VALUE();

        startCovRatio = startCovRatio_;
        endCovRatio = endCovRatio_;
    }

    /**
     * @notice Calculate the high cov ratio fee in the to-asset in a swap.
     * @dev When cov ratio is in the range [startCovRatio, endCovRatio], the marginal cov ratio is
     * (r - startCovRatio) / (endCovRatio - startCovRatio). Here we approximate the high cov ratio cut
     * by calculating the "average" fee.
     * Note: `finalCovRatio` should be greater than `initCovRatio`
     */
    function _highCovRatioFee(uint256 initCovRatio, uint256 finalCovRatio) internal view returns (uint256 fee) {
        if (finalCovRatio > endCovRatio) {
            // invalid swap
            revert WOMBAT_COV_RATIO_LIMIT_EXCEEDED();
        } else if (finalCovRatio <= startCovRatio || finalCovRatio <= initCovRatio) {
            return 0;
        }

        unchecked {
            // 1. Calculate the area of fee(r) = (r - startCovRatio) / (endCovRatio - startCovRatio)
            // when r increase from initCovRatio to finalCovRatio
            // 2. Then multiply it by (endCovRatio - startCovRatio) / (finalCovRatio - initCovRatio)
            // to get the average fee over the range
            uint256 a = initCovRatio <= startCovRatio
                ? 0
                : (initCovRatio - startCovRatio) * (initCovRatio - startCovRatio);
            uint256 b = (finalCovRatio - startCovRatio) * (finalCovRatio - startCovRatio);
            fee = ((b - a) / (finalCovRatio - initCovRatio) / 2).wdiv(endCovRatio - startCovRatio);
        }
    }

    /**
     * @dev Exact output swap (fromAmount < 0) should be only used by off-chain quoting function as it is a gas monster
     */
    function _quoteFrom(
        IAsset fromAsset,
        IAsset toAsset,
        int256 fromAmount
    ) internal view override returns (uint256 actualToAmount, uint256 haircut) {
        (actualToAmount, haircut) = super._quoteFrom(fromAsset, toAsset, fromAmount);

        if (fromAmount >= 0) {
            // normal quote
            uint256 fromAssetCash = fromAsset.cash();
            uint256 fromAssetLiability = fromAsset.liability();
            uint256 finalFromAssetCovRatio = (fromAssetCash + uint256(fromAmount)).wdiv(fromAssetLiability);

            if (finalFromAssetCovRatio > startCovRatio) {
                // charge high cov ratio fee
                uint256 highCovRatioFee = _highCovRatioFee(
                    fromAssetCash.wdiv(fromAssetLiability),
                    finalFromAssetCovRatio
                ).wmul(actualToAmount);

                actualToAmount -= highCovRatioFee;
                unchecked {
                    haircut += highCovRatioFee;
                }
            }
        } else {
            // reverse quote
            uint256 toAssetCash = toAsset.cash();
            uint256 toAssetLiability = toAsset.liability();
            uint256 finalToAssetCovRatio = (toAssetCash + uint256(actualToAmount)).wdiv(toAssetLiability);
            if (finalToAssetCovRatio <= startCovRatio) {
                // happy path: no high cov ratio fee is charged
                return (actualToAmount, haircut);
            } else if (toAssetCash.wdiv(toAssetLiability) >= endCovRatio) {
                // the to-asset exceeds it's cov ratio limit, further swap to increase cov ratio is impossible
                revert WOMBAT_COV_RATIO_LIMIT_EXCEEDED();
            }

            // reverse quote: cov ratio of the to-asset exceed endCovRatio. direct reverse quote is not supported
            // we binary search for a upper bound
            actualToAmount = _findUpperBound(toAsset, fromAsset, uint256(-fromAmount));
            (, haircut) = _quoteFrom(toAsset, fromAsset, int256(actualToAmount));
        }
    }

    /**
     * @notice Binary search to find the upper bound of `fromAmount` required to swap `fromAsset` to `toAmount` of `toAsset`
     * @dev This function should only used as off-chain view function as it is a gas monster
     */
    function _findUpperBound(
        IAsset fromAsset,
        IAsset toAsset,
        uint256 toAmount
    ) internal view returns (uint256 upperBound) {
        uint8 decimals = fromAsset.underlyingTokenDecimals();
        uint256 toWadFactor = DSMath.toWad(1, decimals);
        // the search value uses the same number of digits as the token
        uint256 high = (uint256(fromAsset.liability()).wmul(endCovRatio) - fromAsset.cash()).fromWad(decimals);
        uint256 low = 1;

        // verify `high` is a valid upper bound
        uint256 quote;
        (quote, ) = _quoteFrom(fromAsset, toAsset, int256(high * toWadFactor));
        if (quote < toAmount) revert WOMBAT_COV_RATIO_LIMIT_EXCEEDED();

        // Note: we might limit the maximum number of rounds if the request is always rejected by the RPC server
        while (low < high) {
            unchecked {
                uint256 mid = (low + high) / 2;
                (quote, ) = _quoteFrom(fromAsset, toAsset, int256(mid * toWadFactor));
                if (quote >= toAmount) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            }
        }
        return high * toWadFactor;
    }

    /**
     * @dev take into account high cov ratio fee
     */
    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view override returns (uint256 amount, uint256 withdrewAmount) {
        _checkLiquidity(liquidity);
        _checkSameAddress(fromToken, toToken);
        (amount, withdrewAmount) = _quotePotentialWithdrawFromOtherAsset(fromToken, toToken, liquidity);

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);
        uint256 fromAssetCash = fromAsset.cash() - withdrewAmount;
        uint256 fromAssetLiability = fromAsset.liability() - liquidity;
        uint256 finalFromAssetCovRatio = (fromAssetCash + uint256(withdrewAmount)).wdiv(fromAssetLiability);

        if (finalFromAssetCovRatio > startCovRatio) {
            uint256 highCovRatioFee = _highCovRatioFee(fromAssetCash.wdiv(fromAssetLiability), finalFromAssetCovRatio)
                .wmul(amount);

            amount -= highCovRatioFee;
        }
        withdrewAmount = withdrewAmount.fromWad(fromAsset.underlyingTokenDecimals());
        amount = amount.fromWad(toAsset.underlyingTokenDecimals());
    }
}
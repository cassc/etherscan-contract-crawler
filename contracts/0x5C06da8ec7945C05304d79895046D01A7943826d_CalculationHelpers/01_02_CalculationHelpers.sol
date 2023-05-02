// SPDX-License-Identifier: BSL 1.1 - Blend (c) Non Fungible Trading Ltd.
pragma solidity 0.8.17;

import "lib/solmate/src/utils/SignedWadMath.sol";

library CalculationHelpers {
    int256 private constant _YEAR_WAD = 365 days * 1e18;
    uint256 private constant _LIQUIDATION_THRESHOLD = 100_000;
    uint256 private constant _BASIS_POINTS = 10_000;
    uint256 private constant _MIN_LOAN_TIME = 7200; // 2 hours

    /**
     * @dev Computes the current debt of a borrow given the last time it was touched and the last computed debt.
     * @param amount Principal in ETH
     * @param startTime Start time of the loan
     * @param rate Interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/l6omp0rwnh
     */
    function computeCurrentDebt(
        uint256 amount,
        uint256 rate,
        uint256 startTime
    ) external view returns (uint256) {
        uint256 loanTime = block.timestamp - startTime;
        if (loanTime < _MIN_LOAN_TIME) {
            loanTime = _MIN_LOAN_TIME;
        }
        int256 yearsWad = wadDiv(int256(loanTime) * 1e18, _YEAR_WAD);
        return uint256(wadMul(int256(amount), wadExp(wadMul(yearsWad, bipsToSignedWads(rate)))));
    }

    /**
     * @dev Calculates the current maximum interest rate a specific refinancing
     * auction could settle at currently given the auction's start block and duration.
     * @param startBlock The block the auction started at
     * @param oldRate Previous interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/urasr71dhb
     */
    function calcRefinancingAuctionRate(
        uint256 startBlock,
        uint256 auctionDuration,
        uint256 oldRate
    ) external view returns (uint256) {
        uint256 currentAuctionBlock = block.number - startBlock;
        int256 oldRateWads = bipsToSignedWads(oldRate);

        uint256 auctionT1 = auctionDuration / 5;
        uint256 auctionT2 = (4 * auctionDuration) / 5;

        int256 maxRateWads;
        {
            int256 aInverse = -bipsToSignedWads(15000);
            int256 b = 2;
            int256 maxMinRateWads = bipsToSignedWads(500);

            if (oldRateWads < -((b * aInverse) / 2)) {
                maxRateWads = maxMinRateWads + (oldRateWads ** 2) / aInverse + b * oldRateWads;
            } else {
                maxRateWads = maxMinRateWads - ((b ** 2) * aInverse) / 4;
            }
        }

        int256 startSlope = maxRateWads / int256(auctionT1); // wad-bips per block

        int256 middleSlope = bipsToSignedWads(9000) / int256(3 * auctionDuration / 5) + 1; // wad-bips per block (add one to account for rounding)
        int256 middleB = maxRateWads - int256(auctionT1) * middleSlope;

        if (currentAuctionBlock < auctionT1) {
            return signedWadsToBips(startSlope * int256(currentAuctionBlock));
        } else if (currentAuctionBlock < auctionT2) {
            return signedWadsToBips(middleSlope * int256(currentAuctionBlock) + middleB);
        } else if (currentAuctionBlock < auctionDuration) {
            int256 endSlope;
            int256 endB;
            {
                endSlope =
                    (bipsToSignedWads(_LIQUIDATION_THRESHOLD) -
                        ((int256(auctionT2) * middleSlope) + middleB)) /
                    int256(auctionDuration - auctionT2); // wad-bips per block
                endB =
                    bipsToSignedWads(_LIQUIDATION_THRESHOLD) -
                    int256(auctionDuration) *
                    endSlope;
            }

            return signedWadsToBips(endSlope * int256(currentAuctionBlock) + endB);
        } else {
            return _LIQUIDATION_THRESHOLD;
        }
    }

    /**
     * @dev Converts an integer bips value to a signed wad value.
     */
    function bipsToSignedWads(uint256 bips) public pure returns (int256) {
        return int256((bips * 1e18) / _BASIS_POINTS);
    }

    /**
     * @dev Converts a signed wad value to an integer bips value.
     */
    function signedWadsToBips(int256 wads) public pure returns (uint256) {
        return uint256((wads * int256(_BASIS_POINTS)) / 1e18);
    }
}
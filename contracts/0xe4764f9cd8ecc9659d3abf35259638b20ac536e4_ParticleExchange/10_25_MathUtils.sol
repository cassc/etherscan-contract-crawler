// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library MathUtils {
    uint256 private constant _BASIS_POINTS = 10_000;

    /**
     * @dev Calculate the current interest linearly accrued since the loan start time.
     * @param principal The principal amount of the loan in WEI
     * @param rateBips The yearly interest rate of the loan in bips
     * @param loanStartTime The timestamp at which this loan is opened
     * @return interest The current interest in WEI
     */
    function calculateCurrentInterest(
        uint256 principal,
        uint256 rateBips,
        uint256 loanStartTime
    ) external view returns (uint256 interest) {
        interest = (principal * rateBips * (block.timestamp - loanStartTime)) / (_BASIS_POINTS * 365 days);
    }

    /**
     * @dev Calculates the current allowed auction price (increases linearly in time)
     * @param price The max auction buy price in WEI
     * @param auctionElapsed The current elapsed auction time
     * @param auctionDuration The block span for the auction
     * @return currentAuctionPrice Current allowed auction price in WEI
     */
    function calculateCurrentAuctionPrice(
        uint256 price,
        uint256 auctionElapsed,
        uint256 auctionDuration
    ) external pure returns (uint256 currentAuctionPrice) {
        uint256 auctionPortion = auctionElapsed > auctionDuration ? auctionDuration : auctionElapsed;
        currentAuctionPrice = (price * auctionPortion) / auctionDuration;
    }

    /**
     * @dev Calculates the proportion that goes into treasury
     * @param interest total interest accrued in WEI
     * @param portionBips The treasury proportion in bips
     * @return treasuryAmount Amount goes into treasury in WEI
     */
    function calculateTreasuryProportion(
        uint256 interest,
        uint256 portionBips
    ) external pure returns (uint256 treasuryAmount) {
        treasuryAmount = (interest * portionBips) / _BASIS_POINTS;
    }
}
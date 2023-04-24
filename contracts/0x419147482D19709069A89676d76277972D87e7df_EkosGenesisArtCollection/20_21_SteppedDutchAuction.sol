// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";

contract SteppedDutchAuction {
    uint256 public startTime;
    uint256 public duration;
    uint256 public startPrice;
    uint256 public finalPrice;
    uint256 public priceStep;
    uint256 public timeStepSeconds;

    bool public auctionActive;

    /**************************************************************************
     * CUSTOM ERRORS
     */

    /// Attempting to resume a Dutch auction that has not started
    error DutchAuctionHasNotStarted();

    /// Attempted access to an active Dutch auction
    error DutchAuctionIsActive();

    /// Attempted mint on an inactive Dutch auction
    error DutchAuctionIsNotActive();

    /// Ensure the auction prices, price steps and step interval are valid
    error InvalidDutchAuctionParameters();

    /**************************************************************************
     * EVENTS
     */

    /**
     * @dev emitted when auction has started
     */
    event DutchAuctionStart(
        uint256 indexed auctionStartTime,
        uint256 indexed auctionDuration
    );

    /**
     * @dev emitted when a Dutch auction ends
     */
    event DutchAuctionEnd(uint256 auctionEndTime);

    /**
     * @dev throws when auction is not active
     */
    modifier isAuctionActive() {
        if (!auctionActive) revert DutchAuctionIsNotActive();
        _;
    }

    /**
     * @dev initialise a new Dutch auction
     * @param startPrice_ starting price in wei
     * @param finalPrice_ final resting price in wei
     * @param priceStep_ incremental price decrease in wei
     * @param timeStepSeconds_ time between each price decrease in seconds
     */
    function _createNewAuction(
        uint256 startPrice_,
        uint256 finalPrice_,
        uint256 priceStep_,
        uint256 timeStepSeconds_
    ) internal virtual {
        if (
            startPrice_ < finalPrice_ ||
            (startPrice_ - finalPrice_) < priceStep_
        ) {
            revert InvalidDutchAuctionParameters();
        }

        startPrice = startPrice_;
        finalPrice = finalPrice_;
        priceStep = priceStep_;
        timeStepSeconds = timeStepSeconds_;

        duration =
            Math.ceilDiv((startPrice_ - finalPrice_), priceStep_) *
            timeStepSeconds_;
    }

    /**
     * @dev starts a Dutch auction and emits an event.
     *
     * If an auction has been ended with _endAuction() this will reset the
     *  auction and start it again with all of its initial arguments.
     * If the duration is 0, means that the auction parameters have not been
     *  initialized.
     */
    function _startAuction() internal virtual {
        if (auctionActive) revert DutchAuctionIsActive();
        if (duration == 0) revert InvalidDutchAuctionParameters();

        startTime = block.timestamp;
        auctionActive = true;

        emit DutchAuctionStart(startTime, duration);
    }

    /**
     * @dev if a Dutch auction was ended prematurely using _endAuction it can be
     *  resumed with this function. No time is added to the duration so all
     *  elapsed time during the pause is lost.
     *
     * To restart a stopped Dutch auction from the startPrice with its full
     * duration, use _startAuction() again.
     */
    function _resumeAuction() internal virtual {
        if (startTime == 0) revert DutchAuctionHasNotStarted();
        if (auctionActive) revert DutchAuctionIsActive();

        auctionActive = true; // resume the auction
        emit DutchAuctionStart(startTime, duration);
    }

    /**
     * @dev ends a Dutch auction and emits an event
     */
    function _endAuction() internal virtual isAuctionActive {
        auctionActive = false;

        emit DutchAuctionEnd(block.timestamp);
    }

    /**
     * @dev returns the elapsed time since the start of a Dutch auction.
     *  Returns 0 if the auction has not started or does not exist.
     */
    function _getElapsedAuctionTime() internal view returns (uint256) {
        return startTime > 0 ? block.timestamp - startTime : 0;
    }

    /**
     * @dev returns the remaining time until a Dutch auction's resting price is
     *  hit. If the sale has not started yet, the auction duration is returned.
     *
     * Returning "0" shows the price has reached its final value - the auction
     *  may still be biddable.
     *
     * Use _endAuction() to stop the auction and prevent further bids.
     */
    function getRemainingSaleTime() external view returns (uint256) {
        if (startTime == 0) {
            // not started yet
            return duration;
        } else if (_getElapsedAuctionTime() >= duration) {
            // already at the resting price
            return 0;
        }

        return (startTime + duration) - block.timestamp;
    }

    /**
     * @dev calculates the current Dutch auction price. If not begun, returns
     *  the start price.
     */
    function getAuctionPrice() public view returns (uint256) {
        uint256 elapsed = _getElapsedAuctionTime();

        if (elapsed >= duration) {
            return finalPrice;
        }

        // step function
        uint256 steps = elapsed / timeStepSeconds;
        uint256 auctionPriceDecrease = steps * priceStep;

        return startPrice - auctionPriceDecrease;
    }
}
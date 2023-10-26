// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Kicker Actions
 */
interface IPoolKickerActions {

    /********************/
    /*** Liquidations ***/
    /********************/

    /**
     *  @notice Called by actors to initiate a liquidation.
     *  @param  borrower_     Identifies the loan to liquidate.
     *  @param  npLimitIndex_ Index of the lower bound of `NP` tolerated when kicking the auction.
     */
    function kick(
        address borrower_,
        uint256 npLimitIndex_
    ) external;

    /**
     *  @notice Called by lenders to liquidate the top loan.
     *  @param  index_        The deposit index to use for kicking the top loan.
     *  @param  npLimitIndex_ Index of the lower bound of `NP` tolerated when kicking the auction.
     */
    function lenderKick(
        uint256 index_,
        uint256 npLimitIndex_
    ) external;

    /**
     *  @notice Called by kickers to withdraw their auction bonds (the amount of quote tokens that are not locked in active auctions).
     *  @param  recipient_ Address to receive claimed bonds amount.
     *  @param  maxAmount_ The max amount to withdraw from auction bonds (`WAD` precision). Constrained by claimable amounts and liquidity.
     */
    function withdrawBonds(
        address recipient_,
        uint256 maxAmount_
    ) external;

    /***********************/
    /*** Reserve Auction ***/
    /***********************/

    /**
     *  @notice Called by actor to start a `Claimable Reserve Auction` (`CRA`).
     */
    function kickReserveAuction() external;
}
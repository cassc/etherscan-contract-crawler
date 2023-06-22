// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC20 Pool Borrower Actions
 */
interface IERC20PoolBorrowerActions {

    /**
     *  @notice Called by borrowers to add collateral to the pool and/or borrow quote from the pool.
     *  @dev    Can be called by borrowers with either `0` `amountToBorrow_` or `0` `collateralToPledge_`, if borrower only wants to take a single action. 
     *  @param  borrowerAddress_    The borrower to whom collateral was pledged, and/or debt was drawn for.
     *  @param  amountToBorrow_     The amount of quote tokens to borrow (`WAD` precision).
     *  @param  limitIndex_         Lower bound of `LUP` change (if any) that the borrower will tolerate from a creating or modifying position.
     *  @param  collateralToPledge_ The amount of collateral to be added to the pool (`WAD` precision).
     */
    function drawDebt(
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external;

    /**
     *  @notice Called by borrowers to repay borrowed quote to the pool, and/or pull collateral form the pool.
     *  @dev    Can be called by borrowers with either `0` `maxQuoteTokenAmountToRepay_` or `0` `collateralAmountToPull_`, if borrower only wants to take a single action. 
     *  @param  borrowerAddress_            The borrower whose loan is being interacted with.
     *  @param  maxQuoteTokenAmountToRepay_ The max amount of quote tokens to repay (`WAD` precision).
     *  @param  collateralAmountToPull_     The max amount of collateral to be puled from the pool (`WAD` precision).
     *  @param  recipient_                  The address to receive amount of pulled collateral.
     *  @param  limitIndex_                 Ensures `LUP` has not moved far from state when borrower pulls collateral.
     */
    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_,
        address recipient_,
        uint256 limitIndex_
    ) external;
}
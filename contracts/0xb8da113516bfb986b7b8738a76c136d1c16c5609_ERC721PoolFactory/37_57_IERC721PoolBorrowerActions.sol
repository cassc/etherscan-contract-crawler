// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Borrower Actions
 */
interface IERC721PoolBorrowerActions {

    /**
     *  @notice Called by borrowers to add collateral to the pool and/or borrow quote from the pool.
     *  @dev    Can be called by borrowers with either `0` `amountToBorrow_` or `0` `collateralToPledge`_, if borrower only wants to take a single action. 
     *  @param  borrower_         The address of borrower to drawDebt for.
     *  @param  amountToBorrow_   The amount of quote tokens to borrow (`WAD` precision).
     *  @param  limitIndex_       Lower bound of `LUP` change (if any) that the borrower will tolerate from a creating or modifying position.
     *  @param  tokenIdsToPledge_ Array of token ids to be pledged to the pool.
     */
    function drawDebt(
        address borrower_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256[] calldata tokenIdsToPledge_
    ) external;

    /**
     *  @notice Called by borrowers to repay borrowed quote to the pool, and/or pull collateral form the pool.
     *  @dev    Can be called by borrowers with either `0` `maxQuoteTokenAmountToRepay_` or `0` `collateralAmountToPull_`, if borrower only wants to take a single action. 
     *  @param  borrowerAddress_            The borrower whose loan is being interacted with.
     *  @param  maxQuoteTokenAmountToRepay_ The max amount of quote tokens to repay (`WAD` precision).
     *  @param  noOfNFTsToPull_             The integer number of `NFT` collateral to be puled from the pool.
     *  @param  recipient_                  The address to receive amount of pulled collateral.
     *  @param  limitIndex_                 Ensures `LUP` has not moved far from state when borrower pulls collateral.
     */
    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 noOfNFTsToPull_,
        address recipient_,
        uint256 limitIndex_
    ) external;
}
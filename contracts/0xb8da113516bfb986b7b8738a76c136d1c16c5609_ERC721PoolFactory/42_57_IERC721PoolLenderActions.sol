// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Lender Actions
 */
interface IERC721PoolLenderActions {

    /**
     *  @notice Deposit claimable collateral into a specified bucket.
     *  @param  tokenIds_ Array of token ids to deposit.
     *  @param  index_    The bucket index to which collateral will be deposited.
     *  @param  expiry_   Timestamp after which this transaction will revert, preventing inclusion in a block with unfavorable price.
     *  @return bucketLP_ The amount of `LP `changed for the added collateral.
     */
    function addCollateral(
        uint256[] calldata tokenIds_,
        uint256 index_,
        uint256 expiry_
    ) external returns (uint256 bucketLP_);

    /**
     *  @notice Merge collateral accross a number of buckets, `removalIndexes_` reconstitute an `NFT`.
     *  @param  removalIndexes_   Array of bucket indexes to remove all collateral that the caller has ownership over.
     *  @param  noOfNFTsToRemove_ Intergral number of `NFT`s to remove if collateral amount is met `noOfNFTsToRemove_`, else merge at bucket index, `toIndex_`.
     *  @param  toIndex_          The bucket index to which merge collateral into.
     *  @return collateralMerged_ Amount of collateral merged into `toIndex_` (`WAD` precision).
     *  @return bucketLP_         If non-zero, amount of `LP` in `toIndex_` when collateral is merged into bucket (`WAD` precision). If `0`, no collateral is merged.
     */
    function mergeOrRemoveCollateral(
        uint256[] calldata removalIndexes_,
        uint256 noOfNFTsToRemove_,
        uint256 toIndex_
    ) external returns (uint256 collateralMerged_, uint256 bucketLP_);
}
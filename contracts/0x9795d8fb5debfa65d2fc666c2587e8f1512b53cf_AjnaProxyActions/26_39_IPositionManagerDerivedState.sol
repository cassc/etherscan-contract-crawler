// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Positions Manager Derived State
 */
interface IPositionManagerDerivedState {

    /**
     *  @notice Returns the `LP` accrued to a given `tokenId`, bucket pairing.
     *  @dev    Nested mappings aren't returned normally as part of the default getter for a mapping.
     *  @param  tokenId_ Unique `ID` of token.
     *  @param  index_   Index of bucket to check `LP` balance of.
     *  @return lp_      Balance of `LP` in the bucket for this position.
    */
    function getLP(
        uint256 tokenId_,
        uint256 index_
    ) external view returns (uint256 lp_);

    /**
     *  @notice Returns an array of bucket indexes in which an `NFT` has liquidity.
     *  @dev    Potentially includes buckets that have been bankrupted.
     *  @param  tokenId_  Unique `ID` of token.
     *  @return Array of bucket indexes.
    */
    function getPositionIndexes(
        uint256 tokenId_
    ) external view returns (uint256[] memory);

    /**
     *  @notice Returns an array of bucket indexes in which an `NFT` has liquidity, with bankrupt buckets removed.
     *  @param  tokenId_ Unique `ID` of token.
     *  @return Array of bucket indexes filtered for active liquidity.
    */
    function getPositionIndexesFiltered(
        uint256 tokenId_
    ) external view returns (uint256[] memory);

    /**
     *  @notice Returns information about a given `NFT`.
     *  @param  tokenId_ Unique `ID` of token.
     *  @param  index_   Bucket index to check for position information.
     *  @return `LP` in bucket.
     *  @return Position's deposit time.
    */
    function getPositionInfo(
        uint256 tokenId_,
        uint256 index_
    ) external view returns (uint256, uint256);

    /**
     *  @notice Returns the pool address associated with a positions `NFT`.
     *  @param  tokenId_ The token id of the positions `NFT`.
     *  @return Pool address associated with the `NFT`.
     */
    function poolKey(
        uint256 tokenId_
    ) external view returns (address);

    /**
     *  @notice Checks if a given `pool_` address is an Ajna pool.
     *  @param  pool_       Address of the `Ajna` pool.
     *  @param  subsetHash_ Factory's subset hash pool.
     *  @return isAjnaPool_ `True` if the address to check is an Ajna pool.
    */
    function isAjnaPool(
        address pool_,
        bytes32 subsetHash_
    ) external view returns (bool isAjnaPool_);

    /**
     *  @notice Checks if a given `tokenId` has a given position bucket.
     *  @param  tokenId_           Unique `ID` of token.
     *  @param  index_             Index of bucket to check if in position buckets.
     *  @return bucketInPosition_  `True` if tokenId has the position bucket.
    */
    function isIndexInPosition(
        uint256 tokenId_,
        uint256 index_
    ) external view returns (bool bucketInPosition_);

    /**
     *  @notice Checks if a tokenId has a position in a bucket that was bankrupted.
     *  @param  tokenId_           Unique ID of token.
     *  @param  index_             Index of bucket to check for bankruptcy.
     *  @return isBankrupt_        True if the position in the bucket was bankrupted.
    */
    function isPositionBucketBankrupt(
        uint256 tokenId_,
        uint256 index_
    ) external view returns (bool isBankrupt_);
}
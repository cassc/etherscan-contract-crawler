// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Positions Manager Events
 */
interface IPositionManagerEvents {

    /**
     *  @notice Emitted when an existing `NFT` was burned.
     *  @param  lender  Lender address.
     *  @param  tokenId The token id of the `NFT` that was burned.
     */
    event Burn(
        address indexed lender,
        uint256 indexed tokenId
    );

    /**
     *  @notice Emitted when existing positions were memorialized for a given `NFT`.
     *  @param  tokenId The `tokenId` of the `NFT`.
     *  @param  indexes Bucket indexes of memorialized positions.
     */
    event MemorializePosition(
        address indexed lender,
        uint256 tokenId,
        uint256[] indexes
    );

    /**
     *  @notice Emitted when representative `NFT` minted.
     *  @param  lender  Lender address.
     *  @param  pool    Pool address.
     *  @param  tokenId The `tokenId` of the newly minted `NFT`.
     */
    event Mint(
        address indexed lender,
        address indexed pool,
        uint256 tokenId
    );

    /**
     *  @notice Emitted when a position's liquidity is moved between buckets.
     *  @param  lender         Lender address.
     *  @param  tokenId        The `tokenId` of the newly minted `NFT`.
     *  @param  fromIndex      Index of bucket from where liquidity is moved.
     *  @param  toIndex        Index of bucket where liquidity is moved.
     *  @param  lpRedeemedFrom Amount of `LP` removed from the `from` bucket.
     *  @param  lpAwardedTo    Amount of `LP` credited to the `to` bucket.
     */
    event MoveLiquidity(
        address indexed lender,
        uint256 tokenId,
        uint256 fromIndex,
        uint256 toIndex,
        uint256 lpRedeemedFrom,
        uint256 lpAwardedTo
    );

    /**
     *  @notice Emitted when existing positions were redeemed for a given `NFT`.
     *  @param  tokenId The `tokenId` of the `NFT`.
     *  @param  indexes Bucket indexes of redeemed positions.
     */
    event RedeemPosition(
        address indexed lender,
        uint256 tokenId,
        uint256[] indexes
    );
}
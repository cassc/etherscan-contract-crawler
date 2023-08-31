// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Positions Manager Owner Actions
 */
interface IPositionManagerOwnerActions {

    /**
     *  @notice Called by owners to burn an existing `NFT`.
     *  @dev    Requires that all `LP` have been removed from the `NFT `prior to calling.
     *  @param  pool_    The pool address associated with burned positions NFT
     *  @param  tokenId_ The tokenId of the positions NFT to burn.
     */
    function burn(
        address pool_,
        uint256 tokenId_
    ) external;

    /**
     *  @notice Called to memorialize existing positions with a given NFT.
     *  @dev    The array of buckets is expected to be constructed off chain by scanning events for that lender.
     *  @dev    The NFT must have already been created, and the number of buckets to be memorialized at a time determined by function caller.
     *  @dev    An additional call is made to the pool to transfer the LP from their previous owner, to the Position Manager.
     *  @dev    `Pool.increaseLPAllowance` must be called prior to calling this method in order to allow Position manager contract to transfer LP to be memorialized.
     *  @param  pool_    The pool address associated with positions NFT.
     *  @param  tokenId_ The tokenId of the positions NFT.
     *  @param  indexes_ The array of bucket indexes to memorialize positions.
     */
    function memorializePositions(
        address pool_,
        uint256 tokenId_,
        uint256[] calldata indexes_
    ) external;

    /**
     *  @notice Called by owners to mint and receive an `Ajna` Position `NFT`.
     *  @dev    Position `NFT`s can only be minited with an association to pools that have been deployed by the `Ajna` `ERC20PoolFactory` or `ERC721PoolFactory`.
     *  @param  pool_           The pool address associated with minted positions NFT.
     *  @param  recipient_      Lender address.
     *  @param  poolSubsetHash_ Hash of pool information used to track pool in the factory after deployment.
     *  @return tokenId_ The `tokenId` of the newly minted `NFT`.
     */
    function mint(
        address pool_,
        address recipient_,
        bytes32 poolSubsetHash_
    ) external returns (uint256 tokenId_);

    /**
     *  @notice Called by owners to move liquidity between two buckets.
     *  @param  pool_             The pool address associated with positions NFT.
     *  @param  tokenId_          The tokenId of the positions NFT.
     *  @param  fromIndex_        The bucket index from which liquidity should be moved.
     *  @param  toIndex_          The bucket index to which liquidity should be moved.
     *  @param  expiry_           Timestamp after which this TX will revert, preventing inclusion in a block with unfavorable price.
     *  @param  revertIfBelowLup_ The tx will revert if quote token is moved from above the `LUP` to below the `LUP` (and avoid paying fee for move below `LUP`).
     */
    function moveLiquidity(
        address pool_,
        uint256 tokenId_,
        uint256 fromIndex_,
        uint256 toIndex_,
        uint256 expiry_,
        bool    revertIfBelowLup_
    ) external;

    /**
     *  @notice Called to redeem existing positions with a given `NFT`.
     *  @dev    The array of buckets is expected to be constructed off chain by scanning events for that lender.
     *  @dev    The `NFT` must have already been created, and the number of buckets to be memorialized at a time determined by function caller.
     *  @dev    An additional call is made to the pool to transfer the `LP` Position Manager to owner.
     *  @dev    `Pool.approveLPTransferors` must be called prior to calling this method in order to allow `Position manager` contract to transfer redeemed `LP`.
     *  @param  pool_    The pool address associated with positions NFT.
     *  @param  tokenId_ The tokenId of the positions NFT.
     *  @param  indexes_ The array of bucket indexes to memorialize positions.
     */
    function redeemPositions(
        address pool_,
        uint256 tokenId_,
        uint256[] calldata indexes_
    ) external;

}
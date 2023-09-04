// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Positions Manager Errors
 */
interface IPositionManagerErrors {

    /**
     * @notice User attempting to memorialize position with an allowance set too low.
     */
    error AllowanceTooLow();

    /**
     * @notice User attempting to utilize `LP` from a bankrupt bucket.
     */
    error BucketBankrupt();

    /**
     *  @notice Can't deploy with `ERC20` or `ERC721` factory address `0x`.
     */
    error DeployWithZeroAddress();

    /**
     * @notice User attempting to burn a `LP` `NFT` before removing liquidity.
     */
    error LiquidityNotRemoved();

    /**
     * @notice User not authorized to interact with the specified `NFT`.
     */
    error NoAuth();

    /**
     * @notice `NFT` with provided ID does not exist.
     */
    error NoToken();

    /**
     * @notice User attempted to mint an `NFT` pointing to a pool that wasn't deployed by an `Ajna` factory.
     */
    error NotAjnaPool();

    /**
     * @notice User failed to remove position from their `NFT`.
     */
    error RemovePositionFailed();

    /**
     * @notice User attempting to interact with a pool that doesn't match the pool associated with the `tokenId`.
     */
    error WrongPool();
}
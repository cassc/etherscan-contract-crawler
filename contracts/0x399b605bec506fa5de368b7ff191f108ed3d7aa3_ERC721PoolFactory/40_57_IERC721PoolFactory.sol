// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPoolFactory } from '../IPoolFactory.sol';

/**
 *  @title ERC721 Pool Factory
 *  @dev   Used to deploy non fungible pools.
 */
interface IERC721PoolFactory is IPoolFactory {

    /**************/
    /*** Errors ***/
    /**************/

    /**
     *  @notice User tried to deploy a pool with an array of `tokenIds` that weren't sorted, or contained duplicates.
     */
    error TokenIdSubsetInvalid();

    /**************************/
    /*** External Functions ***/
    /**************************/

    /**
     *  @notice Deploys a cloned pool for the given collateral and quote token.
     *  @dev    Pool must not already exist, and must use `WETH` instead of `ETH`.
     *  @param  collateral_   Address of `NFT` collateral token.
     *  @param  quote_        Address of `NFT` quote token.
     *  @param  tokenIds_     Ids of subset `NFT` tokens.
     *  @param  interestRate_ Initial interest rate of the pool.
     *  @return pool_         Address of the newly created pool.
     */
    function deployPool(
        address collateral_,
        address quote_,
        uint256[] memory tokenIds_,
        uint256 interestRate_
    ) external returns (address pool_);

    /**
     *  @notice User attempted to make pool with non supported `NFT` contract as collateral.
     */
    error NFTNotSupported();
}
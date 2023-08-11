// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPool } from '../IPool.sol';

import { IERC721PoolBorrowerActions } from './IERC721PoolBorrowerActions.sol';
import { IERC721PoolLenderActions }   from './IERC721PoolLenderActions.sol';
import { IERC721PoolImmutables }      from './IERC721PoolImmutables.sol';
import { IERC721PoolState }           from './IERC721PoolState.sol';
import { IERC721PoolEvents }          from './IERC721PoolEvents.sol';
import { IERC721PoolErrors }          from './IERC721PoolErrors.sol';

/**
 * @title ERC721 Pool
 */
interface IERC721Pool is
    IPool,
    IERC721PoolLenderActions,
    IERC721PoolBorrowerActions,
    IERC721PoolState,
    IERC721PoolImmutables,
    IERC721PoolEvents,
    IERC721PoolErrors
{

    /**
     *  @notice Initializes a new pool, setting initial state variables.
     *  @param  tokenIds_  Enumerates `tokenIds_` to be allowed in the pool.
     *  @param  rate_      Initial interest rate of the pool.
     */
    function initialize(
        uint256[] memory tokenIds_,
        uint256 rate_
    ) external;

}
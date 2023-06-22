// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPoolBorrowerActions } from './commons/IPoolBorrowerActions.sol';
import { IPoolLPActions }       from './commons/IPoolLPActions.sol';
import { IPoolLenderActions }   from './commons/IPoolLenderActions.sol';
import { IPoolKickerActions }   from './commons/IPoolKickerActions.sol';
import { IPoolTakerActions }    from './commons/IPoolTakerActions.sol';
import { IPoolSettlerActions }  from './commons/IPoolSettlerActions.sol';

import { IPoolImmutables }      from './commons/IPoolImmutables.sol';
import { IPoolState }           from './commons/IPoolState.sol';
import { IPoolDerivedState }    from './commons/IPoolDerivedState.sol';
import { IPoolEvents }          from './commons/IPoolEvents.sol';
import { IPoolErrors }          from './commons/IPoolErrors.sol';
import { IERC3156FlashLender }  from './IERC3156FlashLender.sol';

/**
 * @title Base Pool Interface
 */
interface IPool is
    IPoolBorrowerActions,
    IPoolLPActions,
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions,
    IPoolImmutables,
    IPoolState,
    IPoolDerivedState,
    IPoolEvents,
    IPoolErrors,
    IERC3156FlashLender
{

}

/// @dev Pool type enum - `ERC20` and `ERC721`
enum PoolType { ERC20, ERC721 }

/// @dev `ERC20` token interface.
interface IERC20Token {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// @dev `ERC721` token interface.
interface IERC721Token {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPositionManagerOwnerActions } from './IPositionManagerOwnerActions.sol';
import { IPositionManagerState }        from './IPositionManagerState.sol';
import { IPositionManagerDerivedState } from './IPositionManagerDerivedState.sol';
import { IPositionManagerErrors }       from './IPositionManagerErrors.sol';
import { IPositionManagerEvents }       from './IPositionManagerEvents.sol';

/**
 *  @title Position Manager Interface
 */
interface IPositionManager is
    IPositionManagerOwnerActions,
    IPositionManagerState,
    IPositionManagerDerivedState,
    IPositionManagerErrors,
    IPositionManagerEvents
{

}
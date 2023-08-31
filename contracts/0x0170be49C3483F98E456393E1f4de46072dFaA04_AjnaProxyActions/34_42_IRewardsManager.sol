// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IRewardsManagerOwnerActions } from './IRewardsManagerOwnerActions.sol';
import { IRewardsManagerState }        from './IRewardsManagerState.sol';
import { IRewardsManagerDerivedState } from './IRewardsManagerDerivedState.sol';
import { IRewardsManagerEvents }       from './IRewardsManagerEvents.sol';
import { IRewardsManagerErrors }       from './IRewardsManagerErrors.sol';

interface IRewardsManager is
    IRewardsManagerOwnerActions,
    IRewardsManagerState,
    IRewardsManagerDerivedState,
    IRewardsManagerErrors,
    IRewardsManagerEvents
{

}
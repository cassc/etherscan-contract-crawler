// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import './IdoStorage/IIdoStorageActions.sol';
import './IdoStorage/IIdoStorageErrors.sol';
import './IdoStorage/IIdoStorageEvents.sol';
import './IdoStorage/IIdoStorageState.sol';


interface IIdoStorage is IIdoStorageState, IIdoStorageActions, IIdoStorageEvents, IIdoStorageErrors  {
}
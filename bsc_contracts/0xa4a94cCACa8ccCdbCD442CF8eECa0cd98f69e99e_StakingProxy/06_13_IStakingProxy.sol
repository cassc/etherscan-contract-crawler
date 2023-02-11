// SPDX-License-Identifier: Apache 2.0
/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020-2022 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "./IStructs.sol";

interface IStakingProxy {
    /// @notice Emitted by StakingProxy when a staking contract is attached.
    /// @param newStakingContractAddress Address of newly attached staking contract.
    event StakingContractAttachedToProxy(address newStakingContractAddress);

    /// @notice Emitted by StakingProxy when a staking contract is detached.
    event StakingContractDetachedFromProxy();

    /// @notice Attach a staking contract; future calls will be delegated to the staking contract.
    /// @dev Note that this is callable only by an authorized address.
    /// @param stakingImplementation Address of staking contract.
    function attachStakingContract(address stakingImplementation) external;

    /// @notice Detach the current staking contract.
    /// @dev Note that this is callable only by an authorized address.
    function detachStakingContract() external;

    /// @notice Batch executes a series of calls to the staking contract.
    /// @param data An array of data that encodes a sequence of functions to call in the staking contracts.
    function batchExecute(bytes[] calldata data) external returns (bytes[] memory batchReturnData);

    /// @notice Asserts initialziation parameters are correct.
    /// @dev Asserts that an epoch is between 5 and 30 days long.
    /// @dev Asserts that 0 < cobb douglas alpha value <= 1.
    /// @dev Asserts that a stake weight is <= 100%.
    /// @dev Asserts that pools allow >= 1 maker.
    /// @dev Asserts that all addresses are initialized.
    function assertValidStorageParams() external view;
}
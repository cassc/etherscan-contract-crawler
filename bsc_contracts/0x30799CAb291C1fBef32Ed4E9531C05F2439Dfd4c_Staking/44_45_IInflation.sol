// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

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

/// @title Inflation Interface - Allows interaction with the Inflation contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IInflation {
    /*
     * STORAGE
     */
    /// @notice Returns the address of the GRG token.
    /// @return Address of the Rigo token contract.
    function rigoToken() external view returns (address);

    /// @notice Returns the address of the GRG staking proxy.
    /// @return Address of the proxy contract.
    function stakingProxy() external view returns (address);

    /// @notice Returns the epoch length in seconds.
    /// @return Number of seconds.
    function epochLength() external view returns (uint48);

    /// @notice Returns epoch slot.
    /// @dev Increases by one every new epoch.
    /// @return Number of latest epoch slot.
    function slot() external view returns (uint32);

    /*
     * CORE FUNCTIONS
     */
    /// @notice Allows staking proxy to mint rewards.
    /// @return mintedInflation Number of allocated tokens.
    function mintInflation() external returns (uint256 mintedInflation);

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @notice Returns whether an epoch has ended.
    /// @return Bool the epoch has ended.
    function epochEnded() external view returns (bool);

    /// @notice Returns the epoch inflation.
    /// @return Value of units of GRG minted in an epoch.
    function getEpochInflation() external view returns (uint256);

    /// @notice Returns how long until next claim.
    /// @return Number in seconds.
    function timeUntilNextClaim() external view returns (uint256);
}
// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2017-2022 RigoBlock, Rigo Investment Sagl, Rigo Intl.

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

/// @title Pool Proxy Factory Interface - Allows external interaction with Pool Proxy Factory.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockPoolProxyFactory {
    /// @notice Emitted when a new pool is created.
    /// @param poolAddress Address of the new pool.
    event PoolCreated(address poolAddress);

    /// @notice Emitted when a new implementation is set by the Rigoblock Dao.
    /// @param implementation Address of the new implementation.
    event Upgraded(address indexed implementation);

    /// @notice Emitted when registry address is upgraded by the Rigoblock Dao.
    /// @param registry Address of the new registry.
    event RegistryUpgraded(address indexed registry);

    /// @notice Returns the implementation address for the pool proxies.
    /// @return Address of the implementation.
    function implementation() external view returns (address);

    /// @notice Creates a new Rigoblock pool.
    /// @param name String of the name.
    /// @param symbol String of the symbol.
    /// @param baseToken Address of the base token.
    /// @return newPoolAddress Address of the new pool.
    /// @return poolId Id of the new pool.
    function createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) external returns (address newPoolAddress, bytes32 poolId);

    /// @notice Allows Rigoblock Dao to update factory pool implementation.
    /// @param newImplementation Address of the new implementation contract.
    function setImplementation(address newImplementation) external;

    /// @notice Allows owner to update the registry.
    /// @param newRegistry Address of the new registry.
    function setRegistry(address newRegistry) external;

    /// @notice Returns the address of the pool registry.
    /// @return Address of the registry.
    function getRegistry() external view returns (address);

    /// @notice Pool initialization parameters.
    /// @params name String of the name (max 31 characters).
    /// @params symbol bytes8 symbol.
    /// @params owner Address of the owner.
    /// @params baseToken Address of the base token.
    struct Parameters {
        string name;
        bytes8 symbol;
        address owner;
        address baseToken;
    }

    /// @notice Returns the pool initialization parameters at proxy deploy.
    /// @return Tuple of the pool parameters.
    function parameters() external view returns (Parameters memory);
}
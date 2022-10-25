// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

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

pragma solidity >=0.7.0 <0.9.0;

/// @title Authority Interface - Allows interaction with the Authority contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IAuthority {
    /// @notice Adds a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionAdded(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the  method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionRemoved(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes an approved method.
    /// @dev Removes a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event RemovedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    /// @notice Approves a new method.
    /// @dev Adds a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter  Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event WhitelistedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    enum Role {
        ADAPTER,
        FACTORY,
        WHITELISTER
    }

    /// @notice Mapping of permission type to bool.
    /// @param Mapping of type of permission to bool is authorized.
    struct Permission {
        mapping(Role => bool) authorized;
    }

    /// @notice Allows a whitelister to whitelist a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    /// @notice We do not save list of approved as better queried by events.
    function addMethod(bytes4 selector, address adapter) external;

    /// @notice Allows a whitelister to remove a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    function removeMethod(bytes4 selector, address adapter) external;

    /// @notice Allows owner to set extension adapter address.
    /// @param adapter Address of the target adapter.
    /// @param isWhitelisted Bool whitelisted.
    function setAdapter(address adapter, bool isWhitelisted) external;

    /// @notice Allows an admin to set factory permission.
    /// @param factory Address of the target factory.
    /// @param isWhitelisted Bool whitelisted.
    function setFactory(address factory, bool isWhitelisted) external;

    /// @notice Allows the owner to set whitelister permission.
    /// @param whitelister Address of the whitelister.
    /// @param isWhitelisted Bool whitelisted.
    /// @notice Whitelister permission is required to approve methods in extensions adapter.
    function setWhitelister(address whitelister, bool isWhitelisted) external;

    /// @notice Returns the address of the adapter associated to the signature.
    /// @param selector Hex of the method signature.
    /// @return Address of the adapter.
    function getApplicationAdapter(bytes4 selector) external view returns (address);

    /// @notice Provides whether a factory is whitelisted.
    /// @param target Address of the target factory.
    /// @return Bool is whitelisted.
    function isWhitelistedFactory(address target) external view returns (bool);

    /// @notice Provides whether an address is whitelister.
    /// @param target Address of the target whitelister.
    /// @return Bool is whitelisted.
    function isWhitelister(address target) external view returns (bool);
}
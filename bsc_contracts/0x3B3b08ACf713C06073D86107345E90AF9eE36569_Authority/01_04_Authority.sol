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

pragma solidity 0.8.17;

import {OwnedUninitialized as Owned} from "../../utils/owned/OwnedUninitialized.sol";
import {IAuthority} from "../interfaces/IAuthority.sol";

/// @title Authority - Allows to set up the base rules of the protocol.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract Authority is Owned, IAuthority {
    mapping(bytes4 => address) private _adapterBySelector;
    mapping(address => Permission) private _permission;
    mapping(Role => address[]) private _roleToList;

    modifier onlyWhitelister() {
        require(isWhitelister(msg.sender), "AUTHORITY_SENDER_NOT_WHITELISTER_ERROR");
        _;
    }

    constructor(address newOwner) {
        owner = newOwner;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @inheritdoc IAuthority
    function addMethod(bytes4 selector, address adapter) external override onlyWhitelister {
        require(_permission[adapter].authorized[Role.ADAPTER], "ADAPTER_NOT_WHITELISTED_ERROR");
        require(_adapterBySelector[selector] == address(0), "SELECTOR_EXISTS_ERROR");
        _adapterBySelector[selector] = adapter;
        emit WhitelistedMethod(msg.sender, adapter, selector);
    }

    /// @inheritdoc IAuthority
    function removeMethod(bytes4 selector, address adapter) external override onlyWhitelister {
        require(_adapterBySelector[selector] != address(0), "AUTHORITY_METHOD_NOT_APPROVED_ERROR");
        delete _adapterBySelector[selector];
        emit RemovedMethod(msg.sender, adapter, selector);
    }

    /// @inheritdoc IAuthority
    function setWhitelister(address whitelister, bool isWhitelisted) external override onlyOwner {
        _changePermission(whitelister, isWhitelisted, Role.WHITELISTER);
    }

    /// @inheritdoc IAuthority
    function setAdapter(address adapter, bool isWhitelisted) external override onlyOwner {
        _changePermission(adapter, isWhitelisted, Role.ADAPTER);
    }

    /// @inheritdoc IAuthority
    function setFactory(address factory, bool isWhitelisted) external override onlyOwner {
        _changePermission(factory, isWhitelisted, Role.FACTORY);
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @inheritdoc IAuthority
    function isWhitelistedFactory(address target) external view override returns (bool) {
        return _permission[target].authorized[Role.FACTORY];
    }

    function getApplicationAdapter(bytes4 selector) external view override returns (address) {
        return _adapterBySelector[selector];
    }

    /// @inheritdoc IAuthority
    function isWhitelister(address target) public view override returns (bool) {
        return _permission[target].authorized[Role.WHITELISTER];
    }

    /*
     * PRIVATE METHODS
     */
    function _changePermission(
        address target,
        bool isWhitelisted,
        Role role
    ) private {
        require(target != address(0), "AUTHORITY_TARGET_NULL_ADDRESS_ERROR");
        if (isWhitelisted) {
            require(!_permission[target].authorized[role], "ALREADY_WHITELISTED_ERROR");
            _permission[target].authorized[role] = isWhitelisted;
            _roleToList[role].push(target);
            emit PermissionAdded(msg.sender, target, uint8(role));
        } else {
            require(_permission[target].authorized[role], "NOT_ALREADY_WHITELISTED");
            delete _permission[target].authorized[role];
            uint256 length = _roleToList[role].length;
            for (uint256 i = 0; i < length; i++) {
                if (_roleToList[role][i] == target) {
                    _roleToList[role][i] = _roleToList[role][length - 1];
                    _roleToList[role].pop();
                    emit PermissionRemoved(msg.sender, target, uint8(role));

                    break;
                }
            }
        }
    }
}
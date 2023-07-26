// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2022 Rigo Intl.

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

import "./RigoblockPoolProxy.sol";
import {IPoolRegistry as PoolRegistry} from "../interfaces/IPoolRegistry.sol";
import "../interfaces/IRigoblockPoolProxyFactory.sol";

/// @title Rigoblock Pool Proxy Factory contract - allows creation of new Rigoblock pools.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract RigoblockPoolProxyFactory is IRigoblockPoolProxyFactory {
    /// @inheritdoc IRigoblockPoolProxyFactory
    address public override implementation;

    address private _registry;

    Parameters private _parameters;

    modifier onlyRigoblockDao() {
        require(PoolRegistry(getRegistry()).rigoblockDao() == msg.sender, "FACTORY_CALLER_NOT_DAO_ERROR");
        _;
    }

    constructor(address newImplementation, address registry) {
        implementation = newImplementation;
        _registry = registry;
    }

    /*
     * PUBLIC FUNCTIONS
     */
    /// @inheritdoc IRigoblockPoolProxyFactory
    function createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) external override returns (address newPoolAddress, bytes32 poolId) {
        (bytes32 newPoolId, RigoblockPoolProxy proxy) = _createPool(name, symbol, baseToken);
        newPoolAddress = address(proxy);
        poolId = newPoolId;
        try PoolRegistry(getRegistry()).register(newPoolAddress, name, symbol, poolId) {
            emit PoolCreated(newPoolAddress);
        } catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory returnData) {
            revert(string(returnData));
        }
    }

    /// @inheritdoc IRigoblockPoolProxyFactory
    function setImplementation(address newImplementation) external override onlyRigoblockDao {
        require(newImplementation != implementation, "FACTORY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newImplementation), "FACTORY_NEW_IMPLEMENTATION_NOT_CONTRACT_ERROR");
        implementation = newImplementation;
        emit Upgraded(newImplementation);
    }

    /// @inheritdoc IRigoblockPoolProxyFactory
    function setRegistry(address newRegistry) external override onlyRigoblockDao {
        require(newRegistry != getRegistry(), "FACTORY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newRegistry), "FACTORY_NEW_REGISTRY_NOT_CONTRACT_ERROR");
        _registry = newRegistry;
        emit RegistryUpgraded(newRegistry);
    }

    /// @notice Returns the pool initialization parameters at proxy deploy.
    /// @return Tuple of the pool parameters.
    function parameters() external view override returns (Parameters memory) {
        return _parameters;
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @inheritdoc IRigoblockPoolProxyFactory
    function getRegistry() public view override returns (address) {
        return _registry;
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Creates a pool and routes to eventful.
    /// @param name String of the name.
    /// @param  symbol String of the symbol.
    /// @param  baseToken Address of the base token.
    function _createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) internal returns (bytes32 salt, RigoblockPoolProxy newProxy) {
        // we omit the encoding params in the constructor in order to guarantee same address for name and owner
        salt = keccak256(abi.encode(name, msg.sender));

        // we write to storage to allow proxy to read initialization parameters
        _parameters = Parameters({name: name, symbol: bytes8(bytes(symbol)), owner: msg.sender, baseToken: baseToken});

        // constructor is null to guarantee same create2 deployed address
        try new RigoblockPoolProxy{salt: salt}() returns (RigoblockPoolProxy proxy) {
            newProxy = proxy;
        } catch Error(string memory revertReason) {
            revert(revertReason);
        } catch (bytes memory) {
            revert("FACTORY_CREATE2_FAILED_ERROR");
        }

        delete _parameters;
    }

    /// @dev Returns whether an address is a contract.
    /// @return Bool target address has code.
    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}
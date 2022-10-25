// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2022 RigoBlock, Rigo Investment Sagl.

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

import "../IRigoblockV3Pool.sol";
import {LibSanitize} from "../../utils/libSanitize/LibSanitize.sol";
import {IAuthority as Authority} from "../interfaces/IAuthority.sol";

import {IPoolRegistry} from "../interfaces/IPoolRegistry.sol";

/// @title Pool Registry - Allows registration of pools.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract PoolRegistry is IPoolRegistry {
    /// @inheritdoc IPoolRegistry
    address public override authority;

    /// @inheritdoc IPoolRegistry
    address public override rigoblockDao;

    mapping(address => bytes32) private _mapIdByAddress;

    mapping(address => PoolMeta) private _poolMetaByAddress;

    /*
     * MODIFIERS
     */
    modifier onlyWhitelistedFactory() {
        require(Authority(authority).isWhitelistedFactory(msg.sender), "REGISTRY_FACTORY_NOT_WHITELISTED_ERROR");
        _;
    }

    modifier onlyPoolOperator(address pool) {
        require(IRigoblockV3Pool(payable(pool)).owner() == msg.sender, "REGISTRY_CALLER_IS_NOT_POOL_OWNER_ERROR");
        _;
    }

    modifier onlyRigoblockDao() {
        require(msg.sender == rigoblockDao, "REGISTRY_CALLER_NOT_DAO_ERROR");
        _;
    }

    modifier whenAddressFree(address pool) {
        require(_mapIdByAddress[pool] == bytes32(0), "REGISTRY_ADDRESS_ALREADY_TAKEN_ERROR");
        _;
    }

    modifier whenPoolRegistered(address pool) {
        require(_mapIdByAddress[pool] != bytes32(0), "REGISTRY_ADDRESS_NOT_REGISTERED_ERROR");
        _;
    }

    constructor(address newAuthority, address newRigoblockDao) {
        authority = newAuthority;
        rigoblockDao = newRigoblockDao;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @inheritdoc IPoolRegistry
    function register(
        address pool,
        string calldata name,
        string calldata symbol,
        bytes32 poolId
    ) external override onlyWhitelistedFactory whenAddressFree(pool) {
        _assertValidNameAndSymbol(name, symbol);
        _mapIdByAddress[pool] = poolId;

        emit Registered(
            msg.sender, // proxy factory
            pool,
            bytes32(bytes(name)),
            bytes32(bytes(symbol)),
            poolId
        );
    }

    /// @inheritdoc IPoolRegistry
    function setAuthority(address newAuthority) external override onlyRigoblockDao {
        require(newAuthority != authority, "REGISTRY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newAuthority), "REGISTRY_NEW_AUTHORITY_NOT_CONTRACT_ERROR");
        authority = newAuthority;
        emit AuthorityChanged(newAuthority);
    }

    /// @inheritdoc IPoolRegistry
    function setMeta(
        address pool,
        bytes32 key,
        bytes32 value
    ) external override onlyPoolOperator(pool) whenPoolRegistered(pool) {
        _poolMetaByAddress[pool].meta[key] = value;
        emit MetaChanged(pool, key, value);
    }

    /// @inheritdoc IPoolRegistry
    function setRigoblockDao(address newRigoblockDao) external override onlyRigoblockDao {
        require(newRigoblockDao != rigoblockDao, "REGISTRY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newRigoblockDao), "REGISTRY_NEW_DAO_NOT_CONTRACT_ERROR");
        rigoblockDao = newRigoblockDao;
        emit RigoblockDaoChanged(newRigoblockDao);
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @inheritdoc IPoolRegistry
    function getPoolIdFromAddress(address pool) external view override returns (bytes32 poolId) {
        poolId = _mapIdByAddress[pool];
    }

    /// @inheritdoc IPoolRegistry
    function getMeta(address pool, bytes32 key) external view override returns (bytes32 poolMeta) {
        return _poolMetaByAddress[pool].meta[key];
    }

    /*
     * INTERNAL FUNCTIONS
     */
    function _assertValidNameAndSymbol(string memory name, string memory symbol) internal pure {
        uint256 nameLength = bytes(name).length;
        // we always want to keep name lenght below 31, for logging bytes32 while making sure that the name toString
        // is stored at slot location and not in the pseudorandom slot allocated to strings longer than 31 bytes.
        require(nameLength >= uint256(4) && nameLength <= uint256(31), "REGISTRY_NAME_LENGTH_ERROR");

        uint256 symbolLength = bytes(symbol).length;
        require(symbolLength >= uint256(3) && symbolLength <= uint256(5), "REGISTRY_SYMBOL_LENGTH_ERROR");

        // check valid characters in name and symbol
        LibSanitize.assertIsValidCheck(name);
        LibSanitize.assertIsValidCheck(symbol);
        LibSanitize.assertIsUppercase(symbol);
    }

    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}
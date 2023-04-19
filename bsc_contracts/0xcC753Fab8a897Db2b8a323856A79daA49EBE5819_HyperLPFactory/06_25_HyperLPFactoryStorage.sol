// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {IHyperLPoolFactoryStorage} from "../interfaces/IHyperStorage.sol";

import {OwnableUninitialized} from "./OwnableUninitialized.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {EnumerableSetMap} from "../utils/EnumerableSetMap.sol";

// solhint-disable-next-line max-states-count
abstract contract HyperLPFactoryStorage is
    OwnableUninitialized, /* XXXX DONT MODIFY ORDERING XXXX */
    Initializable,
    IHyperLPoolFactoryStorage
    // APPEND ADDITIONAL BASE WITH STATE VARS BELOW:
    // XXXX DONT MODIFY ORDERING XXXX
{
    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX
    // solhint-disable-next-line const-name-snakecase
    string public constant version = "1.0.0";
    address public immutable override factory;
    address public poolImplementation;
    address public hyperpoolsDeployer;
    EnumerableSet.AddressSet internal _deployers;
    mapping(address => EnumerableSetMap.Bytes32ToAddressSetMap) internal _pools;
    mapping(address => bool) internal _trustedPools;

    // APPPEND ADDITIONAL STATE VARS BELOW:
    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX

    event UpdatePoolImplementation(
        address previousImplementation,
        address newImplementation
    );

    event UpdateHyperPoolsDeployer(
        address previosHyperPoolsDeployer,
        address newHyperPoolsDeployer
    );

    event PoolTrustToggled(address pool, bool isTrusted);

    constructor(address _uniswapV3Factory) {
        factory = _uniswapV3Factory;
    }

    function initialize(
        address _implementation,
        address _hyperpoolsDeployer,
        address _manager_
    ) external initializer {
        poolImplementation = _implementation;
        hyperpoolsDeployer = _hyperpoolsDeployer;
        _manager = _manager_;
    }

    function setPoolImplementation(address nextImplementation)
        external
        onlyManager
    {
        emit UpdatePoolImplementation(poolImplementation, nextImplementation);
        poolImplementation = nextImplementation;
    }

    function setHyperPoolsDeployer(address nextHyperPoolsDeployer)
        external
        onlyManager
    {
        emit UpdateHyperPoolsDeployer(
            hyperpoolsDeployer,
            nextHyperPoolsDeployer
        );
        hyperpoolsDeployer = nextHyperPoolsDeployer;
    }

    function toggleTrustedPools(address[] memory pools) external onlyManager {
        for (uint256 i = 0; i < pools.length; ) {
            address pool = pools[i];
            bool isTrusted = !_trustedPools[pool];
            _trustedPools[pool] = isTrusted;
            emit PoolTrustToggled(pool, isTrusted);
            unchecked {i++;}
        }
    }
}
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IAddressesRegistry} from "./IAddressesRegistry.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IPoolFactory1155
 * @author Souq.Finance
 * @notice Defines the interface of the factory for ERC1155 pools
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */

interface IPoolFactory1155 {
    /**
     * @dev Emitted when a new pool is deployed using same logic
     * @param user The deployer
     * @param stable The stablecoin address
     * @param tokens The tokens address array
     * @param proxy The proxy address deployed
     * @param index The pool index in the factory
     * @param symbol The symbol of the LP Token
     * @param name The name of the LP Token
     * @param poolTvlLimit The pool TVL limit
     */
    event PoolDeployed(
        address user,
        address stable,
        address[] tokens,
        address proxy,
        uint256 index,
        string symbol,
        string name,
        uint256 poolTvlLimit
    );
    /**
     * @dev Emitted when the fee configuration of the factory changes
     * @param admin The admin address
     * @param feeConfig The new fee Configuration
     */
    event FeeConfigSet(address admin, DataTypes.FactoryFeeConfig feeConfig);
    /**
     * @dev Emitted when the pools are upgraded to new logic
     * @param admin The admin address
     * @param newImplementation The new implementation logic address
     */
    event PoolsUpgraded(address admin, address newImplementation);
    /**
     * @dev Emitted when the onlyPoolAdminDeployments flag changes which enables admins to deploy only
     * @param admin The admin address
     * @param newStatus The new status
     */
    event DeploymentByPoolAdminOnlySet(address admin, bool newStatus);

    /**
     * @dev This function is called only once to initialize the contract. It sets the initial pool logic contract and fee configuration.
     * @param _poolLogic The pool logic contract address
     * @param _feeConfig The factory fee configuration
     */
    function initialize(address _poolLogic, DataTypes.FactoryFeeConfig calldata _feeConfig) external;

    /**
     * @dev This function returns the fee configuration of the contract
     * @return feeConfig The factory fee configuration
     */
    function getFeeConfig() external view returns (DataTypes.FactoryFeeConfig memory);

    /**
     * @dev This function sets the fee configuration of the contract
     * @param newConfig The new factory fee configuration
     */
    function setFeeConfig(DataTypes.FactoryFeeConfig memory newConfig) external;

    /**
     * @dev This function sets the fee configuration of the contract
     * @param poolData The pool data of the liquidity pool to deploy
     * @param symbol The symbol of the LP Token
     * @param name The name of the LP Token
     * @return address of the new proxy
     */
    function deployPool(DataTypes.PoolData memory poolData, string memory symbol, string memory name) external returns (address);

    /**
     * @dev This function returns the count of pools created by the factory.
     * @return uint256 the count
     */
    function getPoolsCount() external view returns (uint256);

    /**
     * @dev This function takes an index as a parameter and returns the address of the pool at that index
     * @param index the pool id
     * @return address the proxy address of the pool
     */
    function getPool(uint256 index) external view returns (address);

    /**
     * @dev This function upgrades the pools to a new logic contract. It is only callable by the upgrader. It increments the pools version and emits a PoolsUpgraded event.
     * @param newLogic The new logic contract address
     */
    function upgradePools(address newLogic) external;

    /**
     * @dev Function to get the version of the pools
     * @return uint256 version of the pools. Only incremeted when the beacon is upgraded
     */
    function getPoolsVersion() external view returns (uint256);

    /**
     * @dev Function to get the version of the proxy
     * @return uint256 version of the contract. Only incremeted when the proxy is upgraded
     */
    function getVersion() external view returns (uint256);

    /**
     * @dev This function sets the status of onlyPoolAdminDeployments. It is only callable by the pool admin.
     * @param status The new status
     */
    function setDeploymentByPoolAdminOnly(bool status) external;
}
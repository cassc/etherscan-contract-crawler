// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Kyoko Governance
 * @author Kyoko
 **/
interface IKyokoPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event KyokoPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event KyokoPoolLiquidatorUpdated(address indexed newAddress);
    event KyokoPoolConfiguratorUpdated(address indexed newAddress);
    event KyokoPoolFactoryUpdated(address indexed newAddress);
    event RateStrategyUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress);
    event AddressRevoke(bytes32 id, address indexed oldAddress);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function revokeAddress(bytes32 id, address oldAddress) external;

    function getAddress(bytes32 id) external view returns (address[] memory);

    function hasRole(bytes32 id, address account) external view returns (bool);

    function getKyokoPool() external view returns (address[] memory);

    function isKyokoPool(address account) external view returns (bool);

    function setKyokoPool(address pool) external;

    function getKyokoPoolLiquidator() external view returns (address[] memory);
    
    function isLiquidator(address account) external view returns (bool);

    function setKyokoPoolLiquidator(address liquidator) external;

    function getKyokoPoolConfigurator() external view returns (address[] memory);
    
    function isConfigurator(address account) external view returns (bool);

    function setKyokoPoolConfigurator(address configurator) external;

    function getKyokoPoolFactory() external view returns (address[] memory);
    
    function isFactory(address account) external view returns (bool);

    function setKyokoPoolFactory(address factory) external;

    function getPoolAdmin() external view returns (address[] memory);
    
    function isAdmin(address account) external view returns (bool);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address[] memory);
    
    function isEmergencyAdmin(address account) external view returns (bool);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address[] memory);

    function isOracle(address account) external view returns (bool);

    function setPriceOracle(address priceOracle) external;

    function getRateStrategy() external view returns (address[] memory);

    function isStrategy(address account) external view returns (bool);

    function setRateStrategy(address rateStrategy) external;
}
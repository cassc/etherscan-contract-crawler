// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';

import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
contract LendingPoolAddressesProvider is Ownable, ILendingPoolAddressesProvider {
	string private _marketId;
	mapping(bytes32 => address) private _addresses;
	address private _liquidationFeeTo;

	bytes32 private constant LENDING_POOL = "LENDING_POOL";
	bytes32 private constant LENDING_POOL_CONFIGURATOR = "LENDING_POOL_CONFIGURATOR";
	bytes32 private constant POOL_ADMIN = "POOL_ADMIN";
	bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
	bytes32 private constant LENDING_POOL_COLLATERAL_MANAGER = "COLLATERAL_MANAGER";
	bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
	bytes32 private constant LENDING_RATE_ORACLE = "LENDING_RATE_ORACLE";

	constructor(string memory marketId) {
		_setMarketId(marketId);
		_liquidationFeeTo = 0xF90C69D16599A5C657A05Fe76Cd22fD9Cab44598;
	}

	/**
	 * @dev Returns the id of the Aave market to which this contracts points to
	 * @return The market id
	 **/
	function getMarketId() external view returns (string memory) {
		return _marketId;
	}

	/**
	 * @dev Allows to set the market which this LendingPoolAddressesProvider represents
	 * @param marketId The market id
	 */
	function setMarketId(string memory marketId) external onlyOwner {
		_setMarketId(marketId);
	}

	/**
	 * @dev General function to update the implementation of a proxy registered with
	 * certain `id`. If there is no proxy registered, it will instantiate one and
	 * set as implementation the `implementationAddress`
	 * IMPORTANT Use this function carefully, only for ids that don't have an explicit
	 * setter function, in order to avoid unexpected consequences
	 * @param id The id
	 * @param implementationAddress The address of the new implementation
	 */
	function setAddressAsProxy(bytes32 id, address implementationAddress) external onlyOwner {
		_updateImpl(id, implementationAddress);
		emit AddressSet(id, implementationAddress, true);
	}

	/**
	 * @dev Sets an address for an id replacing the address saved in the addresses map
	 * IMPORTANT Use this function carefully, as it will do a hard replacement
	 * @param id The id
	 * @param newAddress The address to set
	 */
	function setAddress(bytes32 id, address newAddress) external onlyOwner {
		_addresses[id] = newAddress;
		emit AddressSet(id, newAddress, false);
	}

	/**
	 * @dev Returns an address by id
	 * @return The address
	 */
	function getAddress(bytes32 id) public view returns (address) {
		return _addresses[id];
	}

	/**
	 * @dev Returns the address of the LendingPool proxy
	 * @return The LendingPool proxy address
	 **/
	function getLendingPool() external view returns (address) {
		return getAddress(LENDING_POOL);
	}

	/**
	 * @dev Updates the implementation of the LendingPool, or creates the proxy
	 * setting the new `pool` implementation on the first time calling it
	 * @param pool The new LendingPool implementation
	 **/
	function setLendingPoolImpl(address pool) external onlyOwner {
		_updateImpl(LENDING_POOL, pool);
		emit LendingPoolUpdated(pool);
	}

	/**
	 * @dev Returns the address of the LendingPoolConfigurator proxy
	 * @return The LendingPoolConfigurator proxy address
	 **/
	function getLendingPoolConfigurator() external view returns (address) {
		return getAddress(LENDING_POOL_CONFIGURATOR);
	}

	/**
	 * @dev Updates the implementation of the LendingPoolConfigurator, or creates the proxy
	 * setting the new `configurator` implementation on the first time calling it
	 * @param configurator The new LendingPoolConfigurator implementation
	 **/
	function setLendingPoolConfiguratorImpl(address configurator) external onlyOwner {
		_updateImpl(LENDING_POOL_CONFIGURATOR, configurator);
		emit LendingPoolConfiguratorUpdated(configurator);
	}

	/**
	 * @dev Returns the address of the LendingPoolCollateralManager. Since the manager is used
	 * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
	 * the addresses are changed directly
	 * @return The address of the LendingPoolCollateralManager
	 **/

	function getLendingPoolCollateralManager() external view returns (address) {
		return getAddress(LENDING_POOL_COLLATERAL_MANAGER);
	}

	/**
	 * @dev Updates the address of the LendingPoolCollateralManager
	 * @param manager The new LendingPoolCollateralManager address
	 **/
	function setLendingPoolCollateralManager(address manager) external onlyOwner {
		_addresses[LENDING_POOL_COLLATERAL_MANAGER] = manager;
		emit LendingPoolCollateralManagerUpdated(manager);
	}

	/**
	 * @dev The functions below are getters/setters of addresses that are outside the context
	 * of the protocol hence the upgradable proxy pattern is not used
	 **/

	function getPoolAdmin() external view returns (address) {
		return getAddress(POOL_ADMIN);
	}

	function setPoolAdmin(address admin) external onlyOwner {
		_addresses[POOL_ADMIN] = admin;
		emit ConfigurationAdminUpdated(admin);
	}

	function getEmergencyAdmin() external view returns (address) {
		return getAddress(EMERGENCY_ADMIN);
	}

	function setEmergencyAdmin(address emergencyAdmin) external onlyOwner {
		_addresses[EMERGENCY_ADMIN] = emergencyAdmin;
		emit EmergencyAdminUpdated(emergencyAdmin);
	}

	function getPriceOracle() external view returns (address) {
		return getAddress(PRICE_ORACLE);
	}

	function setPriceOracle(address priceOracle) external onlyOwner {
		_addresses[PRICE_ORACLE] = priceOracle;
		emit PriceOracleUpdated(priceOracle);
	}

	function getLendingRateOracle() external view returns (address) {
		return getAddress(LENDING_RATE_ORACLE);
	}

	function setLendingRateOracle(address lendingRateOracle) external onlyOwner {
		_addresses[LENDING_RATE_ORACLE] = lendingRateOracle;
		emit LendingRateOracleUpdated(lendingRateOracle);
	}

	function getLiquidationFeeTo() external view returns (address) {
		return _liquidationFeeTo;
	}

	function setLiquidationFeeTo(address liquidationFeeTo) external onlyOwner {
		_liquidationFeeTo = liquidationFeeTo;
	}

	/**
	 * @dev Internal function to update the implementation of a specific proxied component of the protocol
	 * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
	 *   as implementation and calls the initialize() function on the proxy
	 * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
	 *   calls the initialize() function via upgradeToAndCall() in the proxy
	 * @param id The id of the proxy to be updated
	 * @param newAddress The address of the new implementation
	 **/
	function _updateImpl(bytes32 id, address newAddress) internal {
		address payable proxyAddress = payable(_addresses[id]);

		InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
			proxyAddress
		);
		bytes memory params = abi.encodeCall(ILendingPool.initialize, ILendingPoolAddressesProvider(address(this)));

		if (proxyAddress == address(0)) {
			proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
			proxy.initialize(newAddress, params);
			_addresses[id] = address(proxy);
			emit ProxyCreated(id, address(proxy));
		} else {
			proxy.upgradeToAndCall(newAddress, params);
		}
	}

	function _setMarketId(string memory marketId) internal {
		_marketId = marketId;
		emit MarketIdSet(marketId);
	}
}
// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/sturdy-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';

import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Sturdy Governance
 * @author Sturdy, inspiration from Aave
 **/
contract LendingPoolAddressesProvider is Ownable, ILendingPoolAddressesProvider {
  string private _marketId;
  // id -> proxyAddress
  mapping(bytes32 => address) private _addresses;

  bytes32 private constant LENDING_POOL = 'LENDING_POOL';
  bytes32 private constant LENDING_POOL_CONFIGURATOR = 'LENDING_POOL_CONFIGURATOR';
  bytes32 private constant POOL_ADMIN = 'POOL_ADMIN';
  bytes32 private constant EMERGENCY_ADMIN = 'EMERGENCY_ADMIN';
  bytes32 private constant LENDING_POOL_COLLATERAL_MANAGER = 'COLLATERAL_MANAGER';
  bytes32 private constant PRICE_ORACLE = 'PRICE_ORACLE';
  bytes32 private constant LENDING_RATE_ORACLE = 'LENDING_RATE_ORACLE';
  bytes32 private constant INCENTIVE_CONTROLLER = 'INCENTIVE_CONTROLLER';
  bytes32 private constant INCENTIVE_TOKEN = 'INCENTIVE_TOKEN';

  constructor(string memory marketId) {
    _setMarketId(marketId);
  }

  /**
   * @dev Returns the id of the Sturdy market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  /**
   * @dev Allows to set the market which this LendingPoolAddressesProvider represents
   * - Caller is only owner which is multisig wallet
   * @param marketId The market id
   */
  function setMarketId(string memory marketId) external payable override onlyOwner {
    _setMarketId(marketId);
  }

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * - Caller is only owner which is multisig wallet
   * @param id The id
   * @param implementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address implementationAddress)
    external
    payable
    override
    onlyOwner
  {
    _updateImpl(id, implementationAddress);
    emit AddressSet(id, implementationAddress, true);
  }

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * - Caller is only owner which is multisig wallet
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external payable override onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress, false);
  }

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /**
   * @dev Returns the address of the LendingPool proxy
   * @return The LendingPool proxy address
   **/
  function getLendingPool() external view override returns (address) {
    return getAddress(LENDING_POOL);
  }

  /**
   * @dev Updates the implementation of the LendingPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * - Caller is only owner which is multisig wallet
   * @param pool The new LendingPool implementation
   **/
  function setLendingPoolImpl(address pool) external payable override onlyOwner {
    _updateImpl(LENDING_POOL, pool);
    emit LendingPoolUpdated(pool);
  }

  /**
   * @dev Returns the address of the IncentiveController proxy
   * @return The IncentiveController proxy address
   **/
  function getIncentiveController() external view override returns (address) {
    return getAddress(INCENTIVE_CONTROLLER);
  }

  /**
   * @dev Updates the implementation of the IncentiveController, or creates the proxy
   * setting the new `incentiveController` implementation on the first time calling it
   * - Caller is only owner which is multisig wallet
   * @param incentiveController The new IncentiveController implementation
   **/
  function setIncentiveControllerImpl(address incentiveController)
    external
    payable
    override
    onlyOwner
  {
    _updateImpl(INCENTIVE_CONTROLLER, incentiveController);
    emit IncentiveControllerUpdated(incentiveController);
  }

  /**
   * @dev Returns the address of the IncentiveToken proxy
   * @return The IncentiveToken proxy address
   **/
  function getIncentiveToken() external view override returns (address) {
    return getAddress(INCENTIVE_TOKEN);
  }

  /**
   * @dev Updates the implementation of the IncentiveToken, or creates the proxy
   * setting the new `incentiveToken` implementation on the first time calling it
   * - Caller is only owner which is multisig wallet
   * @param incentiveToken The new IncentiveToken implementation
   **/
  function setIncentiveTokenImpl(address incentiveToken) external payable override onlyOwner {
    _updateImpl(INCENTIVE_TOKEN, incentiveToken);
    emit IncentiveTokenUpdated(incentiveToken);
  }

  /**
   * @dev Returns the address of the LendingPoolConfigurator proxy
   * @return The LendingPoolConfigurator proxy address
   **/
  function getLendingPoolConfigurator() external view override returns (address) {
    return getAddress(LENDING_POOL_CONFIGURATOR);
  }

  /**
   * @dev Updates the implementation of the LendingPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * - Caller is only owner which is multisig wallet
   * @param configurator The new LendingPoolConfigurator implementation
   **/
  function setLendingPoolConfiguratorImpl(address configurator)
    external
    payable
    override
    onlyOwner
  {
    _updateImpl(LENDING_POOL_CONFIGURATOR, configurator);
    emit LendingPoolConfiguratorUpdated(configurator);
  }

  /**
   * @dev Returns the address of the LendingPoolCollateralManager. Since the manager is used
   * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
   * the addresses are changed directly
   * @return The address of the LendingPoolCollateralManager
   **/

  function getLendingPoolCollateralManager() external view override returns (address) {
    return getAddress(LENDING_POOL_COLLATERAL_MANAGER);
  }

  /**
   * @dev Updates the address of the LendingPoolCollateralManager
   * @param manager The new LendingPoolCollateralManager address
   * - Caller is only owner which is multisig wallet
   **/
  function setLendingPoolCollateralManager(address manager) external payable override onlyOwner {
    _addresses[LENDING_POOL_COLLATERAL_MANAGER] = manager;
    emit LendingPoolCollateralManagerUpdated(manager);
  }

  /**
   * @dev Get the address of poolAdmin which has the permission of pool management
   * @return The address of poolAdmin
   **/
  function getPoolAdmin() external view override returns (address) {
    return getAddress(POOL_ADMIN);
  }

  /**
   * @dev Set the poolAdmin which has the permission of pool management
   * Caller is only owner which is multisig wallet
   * @param admin The address of poolAdmin
   **/
  function setPoolAdmin(address admin) external payable override onlyOwner {
    _addresses[POOL_ADMIN] = admin;
    emit ConfigurationAdminUpdated(admin);
  }

  /**
   * @dev Get the address of emergencyAdmin which has the permission of pool
   * @return The address of emergencyAdmin
   **/
  function getEmergencyAdmin() external view override returns (address) {
    return getAddress(EMERGENCY_ADMIN);
  }

  /**
   * @dev Set the address of emergencyAdmin which has the permission of pool
   * - Caller is only owner which is multisig wallet
   **/
  function setEmergencyAdmin(address emergencyAdmin) external payable override onlyOwner {
    _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
    emit EmergencyAdminUpdated(emergencyAdmin);
  }

  /**
   * @dev Get the address of oracle contract
   * @return The address of oracle contract
   **/
  function getPriceOracle() external view override returns (address) {
    return getAddress(PRICE_ORACLE);
  }

  /**
   * @dev Set the address of oracle contract
   * - Caller is only owner which is multisig wallet
   **/
  function setPriceOracle(address priceOracle) external payable override onlyOwner {
    _addresses[PRICE_ORACLE] = priceOracle;
    emit PriceOracleUpdated(priceOracle);
  }

  /**
   * @dev Get the address of LendingRateOracle contract
   * @return The address of LendingRateOracle contract
   **/
  function getLendingRateOracle() external view override returns (address) {
    return getAddress(LENDING_RATE_ORACLE);
  }

  /**
   * @dev Set the address of LendingRateOracle contract
   * - Caller is only owner which is multisig wallet
   **/
  function setLendingRateOracle(address lendingRateOracle) external payable override onlyOwner {
    _addresses[LENDING_RATE_ORACLE] = lendingRateOracle;
    emit LendingRateOracleUpdated(lendingRateOracle);
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
    bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      proxy.initialize(newAddress, params);
      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      proxy.upgradeToAndCall(newAddress, params);
    }
  }

  /**
   * @dev Set the market index number
   * @param marketId The market id
   */
  function _setMarketId(string memory marketId) internal {
    _marketId = marketId;
    emit MarketIdSet(marketId);
  }
}
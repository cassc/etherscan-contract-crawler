// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/**
 * @title VaultAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 * @author Onebit
 **/
interface IVaultAddressesProvider {
  event MarketIdSet(string newMarketId);
  event VaultUpdated(address indexed newAddress);
  event VaultConfiguratorUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event KYCAdminUpdated(address indexed newAddress);
  event PortfolioManagerUpdated(address indexed newAddress);
  event VaultOperatorUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getVault() external view returns (address);

  function setVaultImpl(address vault) external;

  function getVaultConfigurator() external view returns (address);

  function setVaultConfiguratorImpl(address configurator) external;

  function getVaultOperator() external view returns (address);

  function setVaultOperator(address configurator) external;

  function getVaultAdmin() external view returns (address);

  function setVaultAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getKYCAdmin() external view returns (address);

  function setKYCAdmin(address admin) external;

  function getPortfolioManager() external view returns (address);

  function setPortfolioManager(address admin) external;
}
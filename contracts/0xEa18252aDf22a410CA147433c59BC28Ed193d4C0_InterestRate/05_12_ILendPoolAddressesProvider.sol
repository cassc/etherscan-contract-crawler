// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Unlockd Governance
 * @author Unlockd
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(address indexed newAddress, bytes encodedCallData);
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy, bytes encodedCallData);
  event UNFTRegistryUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event UnlockdDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);
  event NFTXVaultFactoryUpdated(address indexed newAddress);
  event SushiSwapRouterUpdated(address indexed newAddress);
  event LSSVMRouterUpdated(address indexed newAddress);
  event LendPoolLiquidatorUpdated(address indexed newAddress);
  event LtvManagerUpdated(address indexed newAddress);

  /**
   * @dev Returns the id of the Unlockd market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @dev Allows to set the market which this LendPoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string calldata marketId) external;

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param impl The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address impl, bytes memory encodedCallData) external;

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @dev Returns the address of the LendPool proxy
   * @return The LendPool proxy address
   **/
  function getLendPool() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendPool implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  /**
   * @dev Returns the address of the LendPoolConfigurator proxy
   * @return The LendPoolConfigurator proxy address
   **/
  function getLendPoolConfigurator() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendPoolConfigurator implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the LendPool admin
   * @return the LendPoolAdmin address
   **/
  function getPoolAdmin() external view returns (address);

  /**
   * @dev sets the address of the LendPool admin
   * @param admin the LendPoolAdmin address
   **/
  function setPoolAdmin(address admin) external;

  /**
   * @dev returns the address of the emergency admin
   * @return the EmergencyAdmin address
   **/
  function getEmergencyAdmin() external view returns (address);

  /**
   * @dev sets the address of the emergency admin
   * @param admin the EmergencyAdmin address
   **/
  function setEmergencyAdmin(address admin) external;

  /**
   * @dev returns the address of the reserve oracle
   * @return the ReserveOracle address
   **/
  function getReserveOracle() external view returns (address);

  /**
   * @dev sets the address of the reserve oracle
   * @param reserveOracle the ReserveOracle address
   **/
  function setReserveOracle(address reserveOracle) external;

  /**
   * @dev returns the address of the NFT oracle
   * @return the NFTOracle address
   **/
  function getNFTOracle() external view returns (address);

  /**
   * @dev sets the address of the NFT oracle
   * @param nftOracle the NFTOracle address
   **/
  function setNFTOracle(address nftOracle) external;

  /**
   * @dev returns the address of the lendpool loan
   * @return the LendPoolLoan address
   **/
  function getLendPoolLoan() external view returns (address);

  /**
   * @dev sets the address of the lendpool loan
   * @param loan the LendPoolLoan address
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolLoanImpl(address loan, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the UNFT Registry
   * @return the UNFTRegistry address
   **/
  function getUNFTRegistry() external view returns (address);

  /**
   * @dev sets the address of the UNFT registry
   * @param factory the UNFTRegistry address
   **/
  function setUNFTRegistry(address factory) external;

  /**
   * @dev returns the address of the incentives controller
   * @return the IncentivesController address
   **/
  function getIncentivesController() external view returns (address);

  /**
   * @dev sets the address of the incentives controller
   * @param controller the IncentivesController address
   **/
  function setIncentivesController(address controller) external;

  /**
   * @dev returns the address of the UI data provider
   * @return the UIDataProvider address
   **/
  function getUIDataProvider() external view returns (address);

  /**
   * @dev sets the address of the UI data provider
   * @param provider the UIDataProvider address
   **/
  function setUIDataProvider(address provider) external;

  /**
   * @dev returns the address of the Unlockd data provider
   * @return the UnlockdDataProvider address
   **/
  function getUnlockdDataProvider() external view returns (address);

  /**
   * @dev sets the address of the Unlockd data provider
   * @param provider the UnlockdDataProvider address
   **/
  function setUnlockdDataProvider(address provider) external;

  /**
   * @dev returns the address of the wallet balance provider
   * @return the WalletBalanceProvider address
   **/
  function getWalletBalanceProvider() external view returns (address);

  /**
   * @dev sets the address of the wallet balance provider
   * @param provider the WalletBalanceProvider address
   **/
  function setWalletBalanceProvider(address provider) external;

  function getNFTXVaultFactory() external view returns (address);

  /**
   * @dev sets the address of the NFTXVault Factory contract
   * @param factory the NFTXVault Factory address
   **/
  function setNFTXVaultFactory(address factory) external;

  /**
   * @dev returns the address of the SushiSwap router contract
   **/
  function getSushiSwapRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the LSSVM router address
   **/
  function setSushiSwapRouter(address router) external;

  /**
   * @dev returns the address of the LSSVM router contract
   **/
  function getLSSVMRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the SushiSwap router address
   **/
  function setLSSVMRouter(address router) external;

  /**
   * @dev returns the address of the LendPool liquidator contract
   **/
  function getLendPoolLiquidator() external view returns (address);

  /**
   * @dev sets the address of the LendPool liquidator contract
   * @param liquidator the LendPool liquidator address
   **/
  function setLendPoolLiquidator(address liquidator) external;
}
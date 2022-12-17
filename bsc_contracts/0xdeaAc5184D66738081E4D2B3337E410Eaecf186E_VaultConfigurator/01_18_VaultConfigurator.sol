// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
pragma abicoder v2;

import {VersionedInitializable} from './libraries/aave-upgradeability/VersionedInitializable.sol';
import {
  InitializableImmutableAdminUpgradeabilityProxy
} from './libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import {ReserveConfiguration} from './libraries/configuration/ReserveConfiguration.sol';
import {IVaultAddressesProvider} from './interfaces/IVaultAddressesProvider.sol';
import {IVault} from './interfaces/IVault.sol';
import {IERC20Metadata} from './dependencies/openzeppelin/contracts/IERC20Metadata.sol';
import {Errors} from './libraries/helpers/Errors.sol';
import {PercentageMath} from './libraries/math/PercentageMath.sol';
import {DataTypes} from './libraries/types/DataTypes.sol';
import {IInitializableOToken} from './interfaces/IInitializableOToken.sol';
import {IVaultConfigurator} from './interfaces/IVaultConfigurator.sol';

/**
 * @title VaultConfigurator contract
 * @author Aave
 * @author Onebit
 * @dev Implements the configuration methods for the Aave protocol
 **/

contract VaultConfigurator is VersionedInitializable, IVaultConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IVaultAddressesProvider internal addressesProvider;
  IVault internal vault;

  modifier onlyVaultAdmin {
    require(addressesProvider.getVaultAdmin() == msg.sender, Errors.CALLER_NOT_VAULT_ADMIN);
    _;
  }

  modifier onlyEmergencyAdmin {
    require(
      addressesProvider.getEmergencyAdmin() == msg.sender,
      Errors.VPC_CALLER_NOT_EMERGENCY_ADMIN
    );
    _;
  }

  modifier onlyKYCAdmin {
    require(
      addressesProvider.getKYCAdmin() == msg.sender || addressesProvider.getVaultAdmin() == msg.sender,
      Errors.VPC_CALLER_NOT_KYC_ADMIN
    );
    _;
  }

  modifier onlyPortfolioManager {
    require(
      addressesProvider.getPortfolioManager() == msg.sender || addressesProvider.getVaultAdmin() == msg.sender,
      Errors.VPC_CALLER_NOT_PORTFOLIO_MANAGER
    );
    _;
  }

  uint256 internal constant CONFIGURATOR_REVISION = 0x2;

  function getRevision() internal pure override returns (uint256) {
    return CONFIGURATOR_REVISION;
  }

  function initialize(IVaultAddressesProvider provider) public initializer {
    addressesProvider = provider;
    vault = IVault(addressesProvider.getVault());
  }

  function initReserve(InitReserveInput calldata input) external onlyVaultAdmin {
    address oTokenProxyAddress =
      _initContractWithProxy(
        input.oTokenImpl,
        abi.encodeWithSelector(
          IInitializableOToken.initialize.selector,
          vault,
          input.underlyingAsset,
          input.underlyingAssetDecimals,
          input.oTokenName,
          input.oTokenSymbol,
          input.params
        )
      );

    vault.initReserve(oTokenProxyAddress, input.fundAddress);

    DataTypes.ReserveConfigurationMap memory currentConfig = vault.getConfiguration();

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    vault.setConfiguration(currentConfig.data);

    emit ReserveInitialized(
      input.underlyingAsset,
      oTokenProxyAddress
    );
  }

  /**
   * @dev Updates the oToken implementation for the reserve
   **/
  function updateOToken(UpdateOTokenInput calldata input) external onlyVaultAdmin {
    IVault cachedVault = vault;

    DataTypes.ReserveData memory reserveData = cachedVault.getReserveData();

    uint256 decimals = cachedVault.getConfiguration().getParamsMemory();

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableOToken.initialize.selector,
        cachedVault,
        decimals,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeImplementation(
      reserveData.oTokenAddress,
      input.implementation,
      encodedCall
    );

    emit OTokenUpgraded(reserveData.oTokenAddress, input.implementation);
  }

  function setFundAddress(address fundAddress) external onlyVaultAdmin {
    IVault cachedVault = vault;
    vault.setFuncAddress(fundAddress);
  }

  /**
   * @dev Activates a reserve
   **/
  function activateReserve() external onlyVaultAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = vault.getConfiguration();

    currentConfig.setActive(true);

    vault.setConfiguration(currentConfig.data);

    emit ReserveActivated();
  }

  /**
   * @dev Deactivates a reserve
   **/
  function deactivateReserve() external onlyVaultAdmin {

    DataTypes.ReserveConfigurationMap memory currentConfig = vault.getConfiguration();

    currentConfig.setActive(false);

    vault.setConfiguration(currentConfig.data);

    emit ReserveDeactivated();
  }

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow
   *  but allows repayments, liquidations, and withdrawals
   **/
  function freezeReserve() external onlyVaultAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = vault.getConfiguration();

    currentConfig.setFrozen(true);

    vault.setConfiguration(currentConfig.data);

    emit ReserveFrozen();
  }

  /**
   * @dev Unfreezes a reserve
   **/
  function unfreezeReserve() external onlyVaultAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = vault.getConfiguration();

    currentConfig.setFrozen(false);

    vault.setConfiguration(currentConfig.data);

    emit ReserveUnfrozen();
  }

  /**
   * @dev pauses or unpauses all the actions of the protocol, including oToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setVaultPause(bool val) external onlyEmergencyAdmin {
    vault.setPause(val);
  }

  function batchAddToWhitelist(address[] calldata users) external onlyKYCAdmin {
    vault.batchAddToWhitelist(users);
  }

  function addToWhitelist(address user) external onlyKYCAdmin {
    vault.addToWhitelist(user);
  }

  function batchRemoveFromWhitelist(address[] calldata users) external onlyKYCAdmin {
    vault.batchRemoveFromWhitelist(users);
  }

  function removeFromWhitelist(address user) external onlyKYCAdmin {
    vault.removeFromWhitelist(user);
  }

  function setWhitelistExpiration(uint256 expiration) external onlyPortfolioManager {
    vault.setWhitelistExpiration(expiration);
  }

  function initializeNextPeriod(
      uint16 managementFeeRate, uint16 performanceFeeRate, 
      uint128 purchaseUpperLimit,
      uint128 softUpperLimit,
      uint40 purchaseBeginTimestamp, uint40 purchaseEndTimestamp, 
      uint40 redemptionBeginTimestamp)
      external onlyPortfolioManager {
    vault.initializeNextPeriod(
      managementFeeRate, performanceFeeRate, purchaseUpperLimit, softUpperLimit,
      purchaseBeginTimestamp, purchaseEndTimestamp, redemptionBeginTimestamp
    );
  }

  function moveTheLockPeriod(uint40 newPurchaseEndTimestamp) external onlyPortfolioManager {
    vault.moveTheLockPeriod(newPurchaseEndTimestamp);
  }

  function moveTheRedemptionPeriod(uint40 newRedemptionBeginTimestamp) external onlyPortfolioManager {
    vault.moveTheRedemptionPeriod(newRedemptionBeginTimestamp);
  }

  function moveThePurchasePeriod(uint40 newPurchaseBeginTimestamp) external onlyPortfolioManager {
    vault.moveThePurchasePeriod(newPurchaseBeginTimestamp);
  }

  function _initContractWithProxy(address implementation, bytes memory initParams)
    internal
    returns (address)
  {
    InitializableImmutableAdminUpgradeabilityProxy proxy =
      new InitializableImmutableAdminUpgradeabilityProxy(address(this));

    proxy.initialize(implementation, initParams);

    return address(proxy);
  }

  function _upgradeImplementation(
    address proxyAddress,
    address implementation,
    bytes memory initParams
  ) internal {
    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(payable(proxyAddress));

    proxy.upgradeToAndCall(implementation, initParams);
  }



}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "../interfaces/IOpenEdenDesk.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title OpenEdenDesk
 * @notice NAV or statistics related to assets Tranche for OpenEden, the Tranche portfolios are contracts in OpenEden, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract OpenEdenDesk is IOpenEdenDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  AlloyxConfig public config;

  // Alloyx Vault => (OpenEden Pool=>Token Amount)
  mapping(address => mapping(address => uint256)) internal poolToOpenEdenTokenAmountMapping;
  // OpenEden Pool=>Total Token Amount
  mapping(address => uint256) internal OpenEdenTokenTotalAmountMapping;
  // Alloyx Vault => Maple address set
  mapping(address => EnumerableSet.AddressSet) internal vaultToOpenEdenTokenAddresses;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event AddopenEdenVaultAddress(address openEdenVaultAddress);
  event RemoveopenEdenVaultAddress(address openEdenVaultAddress);
  event Deposit(address indexed alloyxPoolAddress, address indexed openEdenVaultAddress, uint256 amount);
  event Withdraw(address indexed alloyxPoolAddress, address indexed openEdenVaultAddress, uint256 amount);

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   */
  function initialize(address _configAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "all user operations should be paused");
    _;
  }

  /**
   * @notice If the transaction is triggered from operator contract
   */
  modifier onlyOperator() {
    require(msg.sender == config.operatorAddress(), "only operator");
    _;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Get the USDC value of the OpenEden wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getOpenEdenWalletUsdcValue(address _vaultAddress) external view override returns (uint256) {
    uint256 length = vaultToOpenEdenTokenAddresses[_vaultAddress].length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getOpenEdenWalletUsdcValueOfPortfolio(_vaultAddress, vaultToOpenEdenTokenAddresses[_vaultAddress].at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the USDC value of the OpenEden wallet on one tranche vault address
   * @param _vaultAddress the pool address of which we calculate the balance
   * @param _address the address of Tranche portfolio
   */
  function getOpenEdenWalletUsdcValueOfPortfolio(address _vaultAddress, address _address) public view override returns (uint256) {
    IERC4626 openEdenVault = IERC4626(_address);
    uint256 balanceOfPool = poolToOpenEdenTokenAmountMapping[_vaultAddress][_address];
    return openEdenVault.convertToAssets(balanceOfPool);
  }

  /**
   * @notice Get the OpenEden Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getOpenEdenVaultAddressesForAlloyxVault(address _vaultAddress) external view override returns (address[] memory) {
    return vaultToOpenEdenTokenAddresses[_vaultAddress].values();
  }

  /**
   * @notice Get the OpenEden Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _OpenEdenVault the address of OpenEden vault
   */
  function getOpenEdenVaultShareForAlloyxVault(address _vaultAddress, address _OpenEdenVault) external view override returns (uint256) {
    return poolToOpenEdenTokenAmountMapping[_vaultAddress][_OpenEdenVault];
  }

  /**
   * @notice Deposit treasury USDC to OpenEden tranche vault
   * @param _vaultAddress the vault address
   * @param _address the address of tranche vault
   * @param _amount the amount to deposit
   */
  function depositToOpenEden(address _vaultAddress, address _address, uint256 _amount) external override onlyOperator {
    IERC4626 openEdenVault = IERC4626(_address);
    config.getUSDC().approve(_address, _amount);
    uint256 shares = openEdenVault.deposit(_amount, address(this));
    poolToOpenEdenTokenAmountMapping[_vaultAddress][_address] = poolToOpenEdenTokenAmountMapping[_vaultAddress][_address].add(shares);
    OpenEdenTokenTotalAmountMapping[_vaultAddress] = OpenEdenTokenTotalAmountMapping[_vaultAddress].add(shares);
    emit Deposit(_vaultAddress, _address, _amount);
    if (!vaultToOpenEdenTokenAddresses[_vaultAddress].contains(_address)) {
      vaultToOpenEdenTokenAddresses[_vaultAddress].add(_address);
    }
  }

  /**
   * @notice Withdraw USDC from OpenEden Tranche portfolio and deposit to treasury
   * @param _vaultAddress the vault address
   * @param _address the address of Tranche portfolio
   * @param _amount the amount to withdraw in USDC
   * @return shares to burn during withdrawal https://github.com/trusttoken/contracts-carbon/blob/c9694396fc01c851a6c006d65c9e3420af723ee2/contracts/openEdenVault.sol#L262
   */
  function withdrawFromOpenEden(address _vaultAddress, address _address, uint256 _amount) external override onlyOperator returns (uint256) {
    IERC4626 openEdenVault = IERC4626(_address);
    uint256 shares = openEdenVault.withdraw(_amount, _vaultAddress, address(this));
    emit Withdraw(_vaultAddress, _address, _amount);
    poolToOpenEdenTokenAmountMapping[_vaultAddress][_address] = poolToOpenEdenTokenAmountMapping[_vaultAddress][_address].sub(shares);
    OpenEdenTokenTotalAmountMapping[_vaultAddress] = OpenEdenTokenTotalAmountMapping[_vaultAddress].sub(shares);
    if (poolToOpenEdenTokenAmountMapping[_vaultAddress][_address] == 0) {
      vaultToOpenEdenTokenAddresses[_vaultAddress].remove(_address);
    }
    return shares;
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20(address _tokenAddress, address _account, uint256 _amount) public onlyAdmin {
    IERC20Upgradeable(_tokenAddress).safeTransfer(_account, _amount);
  }
}
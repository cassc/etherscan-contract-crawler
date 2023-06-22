// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/ITruefiDesk.sol";
import "../interfaces/ITrancheVault.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title TruefiDesk
 * @notice NAV or statistics related to assets Tranche for Truefi, the Tranche portfolios are contracts in Truefi, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract TruefiDesk is ITruefiDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  AlloyxConfig public config;

  // Alloyx Pool => (Truefi Pool=>Token Amount)
  mapping(address => mapping(address => uint256)) internal poolToTruefiTokenAmountMapping;
  // Truefi Pool=>Total Token Amount
  mapping(address => uint256) internal truefiTokenTotalAmountMapping;
  // Alloyx Pool => Maple address set
  mapping(address => EnumerableSet.AddressSet) internal poolToTruefiTokenAddresses;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event AddTrancheVaultAddress(address trancheVaultAddress);
  event RemoveTrancheVaultAddress(address trancheVaultAddress);
  event Deposit(address indexed alloyxPoolAddress, address indexed trancheVaultAddress, uint256 amount);
  event Withdraw(address indexed alloyxPoolAddress, address indexed trancheVaultAddress, uint256 amount);

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
   * @notice Get the USDC value of the truefi wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getTruefiWalletUsdcValue(address _vaultAddress) external view override returns (uint256) {
    uint256 length = poolToTruefiTokenAddresses[_vaultAddress].length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getTruefiWalletUsdcValueOfPortfolio(_vaultAddress, poolToTruefiTokenAddresses[_vaultAddress].at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the USDC value of the truefi wallet on one tranche vault address
   * @param _vaultAddress the pool address of which we calculate the balance
   * @param _address the address of Tranche portfolio
   */
  function getTruefiWalletUsdcValueOfPortfolio(address _vaultAddress, address _address) public view override returns (uint256) {
    ITrancheVault trancheVault = ITrancheVault(_address);
    uint256 balanceOfPool = poolToTruefiTokenAmountMapping[_vaultAddress][_address];
    return trancheVault.convertToAssets(balanceOfPool);
  }

  /**
   * @notice Get the Truefi Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getTruefiVaultAddressesForAlloyxVault(address _vaultAddress) external view override returns (address[] memory) {
    return poolToTruefiTokenAddresses[_vaultAddress].values();
  }

  /**
   * @notice Get the Truefi Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _truefiVault the address of Truefi vault
   */
  function getTruefiVaultShareForAlloyxVault(address _vaultAddress, address _truefiVault) external view override returns (uint256) {
    return poolToTruefiTokenAmountMapping[_vaultAddress][_truefiVault];
  }

  /**
   * @notice Deposit treasury USDC to truefi tranche vault
   * @param _vaultAddress the vault address
   * @param _address the address of tranche vault
   * @param _amount the amount to deposit
   */
  function depositToTruefi(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external override onlyOperator {
    ITrancheVault trancheVault = ITrancheVault(_address);
    config.getUSDC().approve(_address, _amount);
    uint256 shares = trancheVault.deposit(_amount, address(this));
    poolToTruefiTokenAmountMapping[_vaultAddress][_address] = poolToTruefiTokenAmountMapping[_vaultAddress][_address].add(shares);
    truefiTokenTotalAmountMapping[_vaultAddress] = truefiTokenTotalAmountMapping[_vaultAddress].add(shares);
    emit Deposit(_vaultAddress, _address, _amount);
    poolToTruefiTokenAddresses[_vaultAddress].add(_address);
  }

  /**
   * @notice Withdraw USDC from truefi Tranche portfolio and deposit to treasury
   * @param _vaultAddress the vault address
   * @param _address the address of Tranche portfolio
   * @param _amount the amount to withdraw in USDC
   * @return shares to burn during withdrawal https://github.com/trusttoken/contracts-carbon/blob/c9694396fc01c851a6c006d65c9e3420af723ee2/contracts/TrancheVault.sol#L262
   */
  function withdrawFromTruefi(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external override onlyOperator returns (uint256) {
    ITrancheVault trancheVault = ITrancheVault(_address);
    uint256 shares = trancheVault.withdraw(_amount, _vaultAddress, address(this));
    emit Withdraw(_vaultAddress, _address, _amount);
    poolToTruefiTokenAmountMapping[_vaultAddress][_address] = poolToTruefiTokenAmountMapping[_vaultAddress][_address].sub(shares);
    truefiTokenTotalAmountMapping[_vaultAddress] = truefiTokenTotalAmountMapping[_vaultAddress].sub(shares);
    if (poolToTruefiTokenAmountMapping[_vaultAddress][_address] == 0) {
      poolToTruefiTokenAddresses[_vaultAddress].remove(_address);
    }
    return shares;
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) public onlyAdmin {
    IERC20Upgradeable(_tokenAddress).safeTransfer(_account, _amount);
  }
}
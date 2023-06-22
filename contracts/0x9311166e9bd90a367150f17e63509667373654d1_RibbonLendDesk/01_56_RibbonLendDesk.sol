// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IRibbonLendDesk.sol";
import "../interfaces/IRibbonPoolMaster.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title RibbonLendDesk
 * @notice NAV or statistics related to assets managed for RibbonLendDesk, the pool masters are contracts in RibbonLend, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract RibbonLendDesk is IRibbonLendDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;

  // Alloyx Vault => (RibbonLend Pool=>Token Amount)
  mapping(address => mapping(address => uint256)) internal vaultToRibbonLendPoolTokenAmountMapping;
  // Alloyx Vault => RibbonLend Pool Addresses
  mapping(address => EnumerableSet.AddressSet) internal vaultToRibbonLendPoolTokenAddresses;

  AlloyxConfig public config;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event Provide(address indexed alloyxPoolAddress, address indexed poolMasterAddress, uint256 amount);
  event Redeem(address indexed alloyxPoolAddress, address indexed poolMasterAddress, uint256 amount);

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
   * @notice Get the USDC value of the Clear Pool wallet
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getRibbonLendWalletUsdcValue(address _vaultAddress) external view override returns (uint256) {
    uint256 length = vaultToRibbonLendPoolTokenAddresses[_vaultAddress].length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getRibbonLendUsdcValueOfPoolMaster(_vaultAddress, vaultToRibbonLendPoolTokenAddresses[_vaultAddress].at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the USDC value of the Clear Pool wallet on one pool master address
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool master
   */
  function getRibbonLendUsdcValueOfPoolMaster(address _vaultAddress, address _address) public view override returns (uint256) {
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    uint256 exchangeRate = poolMaster.getCurrentExchangeRate();
    uint256 balanceOfWallet = vaultToRibbonLendPoolTokenAmountMapping[_vaultAddress][_address];
    return balanceOfWallet.mul(exchangeRate).div(1e18);
  }

  /**
   * @notice Get the RibbonLend Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getRibbonLendVaultAddressesForAlloyxVault(address _vaultAddress) external view override returns (address[] memory) {
    return vaultToRibbonLendPoolTokenAddresses[_vaultAddress].values();
  }

  /**
   * @notice Get the RibbonLend Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _ribbonLendVault the address of RibbonLend vault
   */
  function getRibbonLendVaultShareForAlloyxVault(address _vaultAddress, address _ribbonLendVault) external view override returns (uint256) {
    return vaultToRibbonLendPoolTokenAmountMapping[_vaultAddress][_ribbonLendVault];
  }

  /**
   * @notice Deposit vault USDC to RibbonLend pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to deposit
   */
  function provide(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external override onlyOperator returns (uint256) {
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    config.getUSDC().approve(_address, _amount);
    uint256 preBalance = poolMaster.balanceOf(address(this));
    poolMaster.provide(_amount, address(this));
    emit Provide(_vaultAddress, _address, _amount);
    uint256 postBalance = poolMaster.balanceOf(address(this));
    uint256 shares = postBalance.sub(preBalance);
    vaultToRibbonLendPoolTokenAmountMapping[_vaultAddress][_address] = vaultToRibbonLendPoolTokenAmountMapping[_vaultAddress][_address].add(shares);
    vaultToRibbonLendPoolTokenAddresses[_vaultAddress].add(_address);
    return shares;
  }

  /**
   * @notice Withdraw USDC from RibbonLend pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to withdraw in pool master tokens https://etherscan.io/address/0xaeb362cc0a50cf6dd36a120c26c21c94382cdbbc#code File 7 of 20 : PoolBase.sol
   */
  function redeem(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external override onlyOperator returns (uint256) {
    IRibbonPoolMaster poolMaster = IRibbonPoolMaster(_address);
    uint256 preUsdcBalance = config.getUSDC().balanceOf(address(this));
    poolMaster.redeem(_amount);
    emit Redeem(_vaultAddress, _address, _amount);
    uint256 postUsdcBalance = config.getUSDC().balanceOf(address(this));
    uint256 usdcAmount = postUsdcBalance.sub(preUsdcBalance);
    config.getUSDC().transfer(_vaultAddress, usdcAmount);
    vaultToRibbonLendPoolTokenAmountMapping[_vaultAddress][_address] = vaultToRibbonLendPoolTokenAmountMapping[_vaultAddress][_address].sub(_amount);
    if (vaultToRibbonLendPoolTokenAmountMapping[_vaultAddress][_address] == 0) {
      vaultToRibbonLendPoolTokenAddresses[_vaultAddress].remove(_address);
    }
    return usdcAmount;
  }
}
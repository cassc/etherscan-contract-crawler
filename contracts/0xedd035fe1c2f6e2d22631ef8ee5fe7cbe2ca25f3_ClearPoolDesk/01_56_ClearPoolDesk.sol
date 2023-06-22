// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IClearPoolDesk.sol";
import "../interfaces/IPoolMaster.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title ClearPoolDesk
 * @notice NAV or statistics related to assets managed for ClearPoolDesk, the pool masters are contracts in ClearPool, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract ClearPoolDesk is IClearPoolDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;

  // Alloyx Pool => (Clear Pool=>Token Amount)
  mapping(address => mapping(address => uint256)) internal poolToClearPoolTokenAmountMapping;
  // Clear Pool => Total Token Amount
  mapping(address => uint256) internal clearPoolTokenTotalAmountMapping;
  // Alloyx Pool => Clear Pool Addresses
  mapping(address => EnumerableSet.AddressSet) internal poolToClearPoolTokenAddresses;

  AlloyxConfig public config;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event Provide(address indexed alloyxPoolAddress, address indexed poolMaster, uint256 amount);
  event Redeem(address indexed alloyxPoolAddress, address indexed poolMaster, uint256 amount);

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
  function getClearPoolWalletUsdcValue(address _vaultAddress) external view override returns (uint256) {
    uint256 length = poolToClearPoolTokenAddresses[_vaultAddress].length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getClearPoolUsdcValueOfPoolMaster(_vaultAddress, poolToClearPoolTokenAddresses[_vaultAddress].at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the USDC value of the Clear Pool wallet on one pool master address
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool master
   */
  function getClearPoolUsdcValueOfPoolMaster(address _vaultAddress, address _address) public view override returns (uint256) {
    IPoolMaster poolMaster = IPoolMaster(_address);
    uint256 exchangeRate = poolMaster.getCurrentExchangeRate();
    uint256 balanceOfWallet = poolToClearPoolTokenAmountMapping[_vaultAddress][_address];
    return balanceOfWallet.mul(exchangeRate).div(1e18);
  }

  /**
   * @notice Get the ClearPool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getClearPoolAddressesForVault(address _vaultAddress) external view override returns (address[] memory) {
    return poolToClearPoolTokenAddresses[_vaultAddress].values();
  }

  /**
   * @notice Get the ClearPool balance for the alloyx vault
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   */
  function getClearPoolBalanceForVault(address _vaultAddress, address _address) external view override returns (uint256) {
    return poolToClearPoolTokenAmountMapping[_vaultAddress][_address];
  }

  /**
   * @notice Deposit treasury USDC to ClearPool pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to deposit
   */
  function provide(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external override onlyOperator returns (uint256) {
    IPoolMaster poolMaster = IPoolMaster(_address);
    config.getUSDC().approve(_address, _amount);
    uint256 preBalance = poolMaster.balanceOf(address(this));
    poolMaster.provide(_amount);
    emit Provide(_vaultAddress, _address, _amount);
    uint256 postBalance = poolMaster.balanceOf(address(this));
    uint256 shares = postBalance.sub(preBalance);
    poolToClearPoolTokenAmountMapping[_vaultAddress][_address] = poolToClearPoolTokenAmountMapping[_vaultAddress][_address].add(shares);
    clearPoolTokenTotalAmountMapping[_vaultAddress] = clearPoolTokenTotalAmountMapping[_vaultAddress].add(shares);
    poolToClearPoolTokenAddresses[_vaultAddress].add(_address);
    return shares;
  }

  /**
   * @notice Withdraw USDC from ClearPool pool master
   * @param _vaultAddress the vault address
   * @param _address the address of pool master
   * @param _amount the amount to withdraw in pool master tokens
   */
  function redeem(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external override onlyOperator returns (uint256) {
    IPoolMaster poolMaster = IPoolMaster(_address);
    uint256 preUsdcBalance = config.getUSDC().balanceOf(address(this));
    poolMaster.redeem(_amount);
    emit Redeem(_vaultAddress, _address, _amount);
    uint256 postUsdcBalance = config.getUSDC().balanceOf(address(this));
    uint256 usdcAmount = postUsdcBalance.sub(preUsdcBalance);
    config.getUSDC().transfer(_vaultAddress, usdcAmount);
    poolToClearPoolTokenAmountMapping[_vaultAddress][_address] = poolToClearPoolTokenAmountMapping[_vaultAddress][_address].sub(_amount);
    clearPoolTokenTotalAmountMapping[_vaultAddress] = clearPoolTokenTotalAmountMapping[_vaultAddress].sub(_amount);
    if (poolToClearPoolTokenAmountMapping[_vaultAddress][_address] == 0) {
      poolToClearPoolTokenAddresses[_vaultAddress].remove(_address);
    }
    return usdcAmount;
  }
}
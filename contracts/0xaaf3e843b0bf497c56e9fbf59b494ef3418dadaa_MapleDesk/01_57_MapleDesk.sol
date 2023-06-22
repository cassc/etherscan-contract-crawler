// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IMapleDesk.sol";
import "../interfaces/IPool.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title MapleDesk
 * @notice NAV or statistics related to assets managed for Maple
 * @author AlloyX
 */
contract MapleDesk is IMapleDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // Alloyx Pool => (Maple Pool=>Token Amount)
  mapping(address => mapping(address => uint256)) internal poolToMapleTokenAmountMapping;
  // Maple Pool => Total Token Amount
  mapping(address => uint256) internal mapleTokenTotalAmountMapping;
  // Alloyx Pool => Maple Pool Addresses
  mapping(address => EnumerableSet.AddressSet) internal poolToMapleTokenAddresses;

  AlloyxConfig public config;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event Deposit(address indexed alloyxPoolAddress, address indexed poolAddress, uint256 amount);
  event Withdraw(address indexed alloyxPoolAddress, address indexed poolAddress, uint256 amount);
  event RequestWithdraw(address indexed poolAddres, uint256 shares);
  event CancelWithdraw(address indexed poolAddres);

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
   * @notice Get the Usdc value of the truefi wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getMapleWalletUsdcValue(address _vaultAddress) external view override returns (uint256) {
    uint256 length = poolToMapleTokenAddresses[_vaultAddress].length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getMapleWalletUsdcValueOfPool(_vaultAddress, poolToMapleTokenAddresses[_vaultAddress].at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the Maple Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getMaplePoolAddressesForVault(address _vaultAddress) external view override returns (address[] memory) {
    return poolToMapleTokenAddresses[_vaultAddress].values();
  }

  /**
   * @notice Get the Usdc value of the Maple wallet
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool
   */
  function getMapleWalletUsdcValueOfPool(address _vaultAddress, address _address) public view override returns (uint256) {
    uint256 totalToken = mapleTokenTotalAmountMapping[_address];
    if (totalToken == 0) {
      return 0;
    }
    uint256 thisAlloyxPoolTokens = poolToMapleTokenAmountMapping[_vaultAddress][_address];
    IPool pool = IPool(_address);
    return pool.convertToExitAssets(thisAlloyxPoolTokens);
  }

  /**
   * @notice Get the Maple balance
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _address the address of pool
   */
  function getMapleBalanceOfPool(address _vaultAddress, address _address) external view override returns (uint256) {
    return poolToMapleTokenAmountMapping[_vaultAddress][_address];
  }

  /**
   * @notice Deposit treasury USDC to Maple pool
   * @param _vaultAddress the vault address
   * @param _address the address of pool
   * @param _amount the amount to deposit
   */
  function depositToMaple(
    address _vaultAddress,
    address _address,
    uint256 _amount
  ) external override onlyOperator returns (uint256) {
    IPool pool = IPool(_address);
    config.getUSDC().approve(_address, _amount);
    uint256 shares = pool.deposit(_amount, address(this));
    emit Deposit(_vaultAddress, _address, _amount);
    poolToMapleTokenAmountMapping[_vaultAddress][_address] = poolToMapleTokenAmountMapping[_vaultAddress][_address].add(shares);
    mapleTokenTotalAmountMapping[_address] = mapleTokenTotalAmountMapping[_address].add(shares);
    poolToMapleTokenAddresses[_vaultAddress].add(_address);
    return shares;
  }

  /**
   * @notice Withdraw USDC from Maple managed portfolio and deposit to treasury
   * @param _vaultAddress the vault address
   * @param _address the address of pool
   * @param _shares the amount to withdraw in shares https://github.com/maple-labs/maple-core/blob/4577df4ac7e9ffd6a23fe6550c1d6ef98c5185ea/contracts/Pool.sol#L429
   */
  function withdrawFromMaple(
    address _vaultAddress,
    address _address,
    uint256 _shares
  ) external override onlyOperator returns (uint256) {
    IPool pool = IPool(_address);
    uint256 assetValue = pool.redeem(_shares, address(this), address(this));
    emit Withdraw(_vaultAddress, _address, assetValue);
    config.getUSDC().transfer(_vaultAddress, assetValue);
    poolToMapleTokenAmountMapping[_vaultAddress][_address] = poolToMapleTokenAmountMapping[_vaultAddress][_address].sub(_shares);
    mapleTokenTotalAmountMapping[_address] = mapleTokenTotalAmountMapping[_address].sub(_shares);
    if (poolToMapleTokenAmountMapping[_vaultAddress][_address] == 0) {
      poolToMapleTokenAddresses[_vaultAddress].remove(_address);
    }
    return assetValue;
  }

  /**
   * @notice Initiate the countdown from the lockup period on Maple side
   * @param _vaultAddress the vault address
   * @param _address the address of pool
   * @param _shares the amount to withdraw in shares https://github.com/maple-labs/maple-core/blob/4577df4ac7e9ffd6a23fe6550c1d6ef98c5185ea/contracts/Pool.sol#L429
   */
  function requestWithdraw(
    address _vaultAddress,
    address _address,
    uint256 _shares
  ) external override onlyOperator {
    require(poolToMapleTokenAmountMapping[_vaultAddress][_address] >= _shares, "the vault does not have enough investment in the pool");
    IPool pool = IPool(_address);
    pool.requestRedeem(_shares, _address);
    emit RequestWithdraw(_address, _shares);
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
  ) public override onlyAdmin {
    IERC20Upgradeable(_tokenAddress).safeTransfer(_account, _amount);
  }
}
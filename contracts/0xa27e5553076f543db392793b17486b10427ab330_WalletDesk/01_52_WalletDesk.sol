// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title WalletDesk
 * @notice NAV or statistics related to assets managed for Protocols in other chains, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract WalletDesk is IWalletDesk, AdminUpgradeable {
  using ConfigHelper for AlloyxConfig;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  mapping(address => uint256) public vaultToUsdcValue;

  AlloyxConfig public config;

  event AlloyxConfigUpdated(address indexed who, address configAddress);

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
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Get the Usdc value of the credix wallet
   * @param _vaultAddress the address of pool
   */
  function getWalletUsdcValue(address _vaultAddress) external view override returns (uint256) {
    return vaultToUsdcValue[_vaultAddress];
  }

  /**
   * @notice Set the Usdc value
   * @param _vaultAddress the vault address
   * @param _amount the amount to transfer
   */
  function setUsdcValueForPool(address _vaultAddress, uint256 _amount) external override {
    require(msg.sender == config.operatorAddress() || isAdmin(msg.sender), "only operator or admin");
    vaultToUsdcValue[_vaultAddress] = _amount;
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
  ) external onlyAdmin {
    IERC20Upgradeable(_tokenAddress).safeTransfer(_account, _amount);
  }
}
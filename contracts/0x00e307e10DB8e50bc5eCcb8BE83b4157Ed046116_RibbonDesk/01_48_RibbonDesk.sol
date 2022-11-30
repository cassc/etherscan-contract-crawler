// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";
import "./interfaces/IRibbonDesk.sol";
import "./interfaces/IRibbonThetaYearnVault.sol";

/**
 * @title RibbonDesk
 * @notice NAV or statistics related to assets managed for RibbonDesk, the pool masters are contracts in Ribbon Finance, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract RibbonDesk is IRibbonDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  AlloyxConfig public config;
  EnumerableSet.AddressSet ribbonVaultAddresses;
  event AlloyxConfigUpdated(address indexed who, address configAddress);

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
   * @notice Get the token balance on one ribbon vault address
   * @param _address the address of ribbon vault
   */
  function balanceOfRibbonVaultToken(address _address) external view returns (uint256) {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_address);
    return ribbonVault.balanceOf(address(this));
  }

  /**
   * @notice Get the Usdc value of the Ribbon wallet
   */
  function getRibbonWalletUsdcValue() external view override returns (uint256) {
    uint256 length = ribbonVaultAddresses.length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getRibbonUsdcValueOfVault(ribbonVaultAddresses.at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the Usdc value of the Clear Pool wallet on one ribbon vault address
   * @param _address the address of ribbon vault
   */
  function getRibbonUsdcValueOfVault(address _address) public view returns (uint256) {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_address);
    return ribbonVault.accountVaultBalance(address(this));
  }

  /**
   * @notice Add ribbon vault address to the list
   * @param _address the address of ribbon vault
   */
  function addRibbonVaultAddress(address _address) external onlyAdmin {
    require(!ribbonVaultAddresses.contains(_address), "the address already inside the list");
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_address);
    require(
      ribbonVault.balanceOf(address(this)) > 0,
      "the balance of the desk on the ribbon vault should not be 0 before adding"
    );
    ribbonVaultAddresses.add(_address);
  }

  /**
   * @notice Remove ribbon vault address to the list
   * @param _address the address of ribbon vault
   */
  function removeRibbonVaultAddress(address _address) external onlyAdmin {
    require(ribbonVaultAddresses.contains(_address), "the address should be inside the list");
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_address);
    require(
      ribbonVault.balanceOf(address(this)) == 0,
      "the balance of the desk on the ribbon vault should be 0 before removing"
    );
    ribbonVaultAddresses.remove(_address);
  }

  /**
   * @notice Deposits the `asset` from msg.sender.
   * @param _amount is the amount of `asset` to deposit
   * @param _vault is the address of the vault
   */
  function deposit(uint256 _amount, address _vault) external {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_vault);
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(_vault, _amount);
    ribbonVault.deposit(_amount);
    if (!ribbonVaultAddresses.contains(_vault)) {
      ribbonVaultAddresses.add(_vault);
    }
  }

  /**
   * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
   * @param _amount is the amount to withdraw
   * @param _vault is the address of the vault
   */
  function withdrawInstantly(uint256 _amount, address _vault) external {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_vault);
    ribbonVault.withdrawInstantly(_amount);
  }

  /**
   * @notice Initiates a withdrawal that can be processed once the round completes
   * @param _numShares is the number of shares to withdraw
   * @param _vault is the address of the vault
   */
  function initiateWithdraw(uint256 _numShares, address _vault) external {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_vault);
    ribbonVault.withdrawInstantly(_numShares);
  }

  /**
   * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
   * @param _vault is the address of the vault
   */
  function completeWithdraw(address _vault) external {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_vault);
    ribbonVault.completeWithdraw();
  }

  /**
   * @notice Stakes a users vault shares
   * @param _numShares is the number of shares to stake
   * @param _vault is the address of the vault
   */
  function stake(uint256 _numShares, address _vault) external {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_vault);
    ribbonVault.approve(_vault, _numShares);
    ribbonVault.stake(_numShares);
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
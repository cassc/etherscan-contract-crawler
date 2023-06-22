// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IRibbonDesk.sol";
import "../interfaces/IRibbonThetaYearnVault.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

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

  // Alloyx Pool => (Ribbon Pool=>Token Amount)
  mapping(address => mapping(address => uint256)) internal poolToRibbonPoolTokenAmountMapping;
  // Alloyx Pool => Ribbon Pool Addresses
  mapping(address => EnumerableSet.AddressSet) internal poolToRibbonPoolTokenAddresses;
  // Alloyx Pool => (Ribbon Pool=>Token Amount to Withdraw)
  mapping(address => mapping(address => uint256)) internal poolToRibbonPoolTokenToWithdrawMapping;
  // Ribbon Vault => Alloyx Vault Addresses
  mapping(address => EnumerableSet.AddressSet) internal ribbonVaultToAlloyxVaultToWithrawMapping;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event AddRibbonVaultAddress(address ribbonVaultAddress);
  event RemoveRibbonVaultAddress(address ribbonVaultAddress);
  event Deposit(address indexed ribbonVaultAddress, uint256 amount);
  event WithdrawInstantly(address indexed ribbonVaultAddress, uint256 amount);
  event InitiateWithdraw(address indexed ribbonVaultAddress, uint256 numOfshare);
  event CompleteWithdraw(address indexed ribbonVaultAddress);
  event Stake(address indexed ribbonVaultAddress, uint256 numOfshare);

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
   * @notice Get the Usdc value of the Ribbon wallet
   * @param _vaultAddress the address of alloyx vault
   */
  function getRibbonWalletUsdcValue(address _vaultAddress) external view override returns (uint256) {
    uint256 length = poolToRibbonPoolTokenAddresses[_vaultAddress].length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getRibbonUsdcValueOfVault(_vaultAddress, poolToRibbonPoolTokenAddresses[_vaultAddress].at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the Ribbon Pool addresses for the alloyx vault
   * @param _vaultAddress the vault address
   */
  function getRibbonVaultAddressesForAlloyxVault(address _vaultAddress) external view override returns (address[] memory) {
    return poolToRibbonPoolTokenAddresses[_vaultAddress].values();
  }

  /**
   * @notice Get the Ribbon Vault balance for the alloyx vault
   * @param _vaultAddress the address of alloyx vault
   * @param _ribbonVault the address of ribbon vault
   */
  function getRibbonVaultShareForAlloyxVault(address _vaultAddress, address _ribbonVault) external view override returns (uint256) {
    return poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVault];
  }

  /**
   * @notice Get the Usdc value of the Clear Pool wallet on one ribbon vault address
   * @param _vaultAddress the address of alloyx vault
   * @param _ribbonVault the address of ribbon vault
   */
  function getRibbonUsdcValueOfVault(address _vaultAddress, address _ribbonVault) public view override returns (uint256) {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_ribbonVault);
    uint256 alloyxVaultShare = poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVault];
    uint256 totalShare = ribbonVault.shares(address(this));
    if (totalShare == 0) {
      return 0;
    }
    return ribbonVault.accountVaultBalance(address(this)).mul(alloyxVaultShare).div(totalShare);
  }

  /**
   * @notice Deposits the `asset` from vault.
   * @param _vaultAddress the vault address
   * @param _amount is the amount of `asset` to deposit
   * @param _ribbonVault is the address of the vault
   */
  function deposit(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _amount
  ) external override onlyOperator {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_ribbonVault);
    config.getUSDC().approve(_ribbonVault, _amount);
    uint256 preShare = ribbonVault.shares(address(this));
    ribbonVault.deposit(_amount);
    uint256 postShare = ribbonVault.shares(address(this));
    uint256 shares = postShare.sub(preShare);
    emit Deposit(_ribbonVault, _amount);
    if (!ribbonVaultAddresses.contains(_ribbonVault)) {
      ribbonVaultAddresses.add(_ribbonVault);
    }
    poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVault] = poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVault].add(shares);
    poolToRibbonPoolTokenAddresses[_vaultAddress].add(_ribbonVault);
  }

  /**
   * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
   * @param _vaultAddress the vault address
   * @param _ribbonVault is the address of the vault
   * @param _amount is the amount to withdraw in USDC https://github.com/ribbon-finance/ribbon-v2/blob/e9270281c7aa7433851ecee7f326c37bce28aec1/contracts/vaults/YearnVaults/RibbonThetaYearnVault.sol#L236
   */
  function withdrawInstantly(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _amount
  ) external override onlyOperator {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_ribbonVault);
    uint256 preShare = ribbonVault.shares(address(this));
    ribbonVault.withdrawInstantly(_amount);
    uint256 postShare = ribbonVault.shares(address(this));
    config.getUSDC().transfer(_vaultAddress, _amount);
    uint256 reducedShare = preShare.sub(postShare);
    poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVault] = poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVault].sub(reducedShare);
    emit WithdrawInstantly(_ribbonVault, _amount);
  }

  /**
   * @notice Initiates a withdrawal that can be processed once the round completes
   * @param _vaultAddress the vault address
   * @param _numShares is the number of shares to withdraw https://github.com/ribbon-finance/ribbon-v2/blob/e9270281c7aa7433851ecee7f326c37bce28aec1/contracts/vaults/YearnVaults/RibbonThetaYearnVault.sol#L263
   * @param _ribbonVault is the address of the vault
   */
  function initiateWithdraw(
    address _vaultAddress,
    address _ribbonVault,
    uint256 _numShares
  ) external override onlyOperator {
    require(poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVault] >= _numShares, "the shares are not enough for withdrawal");
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_ribbonVault);
    ribbonVault.initiateWithdraw(_numShares);
    poolToRibbonPoolTokenToWithdrawMapping[_vaultAddress][_ribbonVault] = _numShares;
    ribbonVaultToAlloyxVaultToWithrawMapping[_ribbonVault].add(_vaultAddress);
    emit InitiateWithdraw(_ribbonVault, _numShares);
  }

  /**
   * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
   * @param _vaultAddress the vault address
   * @param _poolAddress the pool address
   */
  function completeWithdraw(address _vaultAddress, address _poolAddress) external override onlyOperator {
    IRibbonThetaYearnVault ribbonVault = IRibbonThetaYearnVault(_poolAddress);
    uint256 preShare = ribbonVault.shares(address(this));
    uint256 preUsdcValue = config.getUSDC().balanceOf(address(this));
    ribbonVault.completeWithdraw();
    uint256 postShare = ribbonVault.shares(address(this));
    uint256 postUsdcValue = config.getUSDC().balanceOf(address(this));
    uint256 decreasedShares = preShare.sub(postShare);
    uint256 remainingShares = decreasedShares;
    uint256 increasedUsdcValue = postUsdcValue.sub(preUsdcValue);
    for (uint256 i = 0; i < ribbonVaultToAlloyxVaultToWithrawMapping[_poolAddress].length(); i++) {
      (bool shouldStop, uint256 usedShares) = withdrawForVault(_vaultAddress, _poolAddress, increasedUsdcValue, decreasedShares, remainingShares);
      remainingShares = remainingShares.sub(usedShares);
      if (shouldStop) {
        break;
      }
    }
    emit CompleteWithdraw(_poolAddress);
  }

  /**
   * @notice Transfer USDC from ribbon desk to different vault
   * @param _ribbonVaultAddress the ribbon vault address
   * @param _totalUsdc total amount of USDC of this round withdrawal of USDC
   * @param _totalShare total share of Ribbon token has been withdrawn
   * @param _remainingShare the remaining share of Ribbon token for this round of withdrawal
   */
  function withdrawForVault(
    address _vaultAddress,
    address _ribbonVaultAddress,
    uint256 _totalUsdc,
    uint256 _totalShare,
    uint256 _remainingShare
  ) internal returns (bool, uint256) {
    bool shouldStop = false;
    uint256 sharesOwned = poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVaultAddress];
    uint256 sharesToWithdraw = poolToRibbonPoolTokenToWithdrawMapping[_vaultAddress][_ribbonVaultAddress];
    if (sharesOwned <= sharesToWithdraw) {
      sharesToWithdraw = sharesOwned;
    }
    if (sharesToWithdraw >= _remainingShare) {
      sharesToWithdraw = _remainingShare;
      shouldStop = true;
    }
    uint256 usdcValueToWithdraw = _totalUsdc.mul(sharesToWithdraw).div(_totalShare);
    config.getUSDC().transfer(_vaultAddress, usdcValueToWithdraw);
    poolToRibbonPoolTokenToWithdrawMapping[_vaultAddress][_ribbonVaultAddress] = poolToRibbonPoolTokenToWithdrawMapping[_vaultAddress][_ribbonVaultAddress].sub(sharesToWithdraw);
    poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVaultAddress] = poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVaultAddress].sub(sharesToWithdraw);
    if (poolToRibbonPoolTokenAmountMapping[_vaultAddress][_ribbonVaultAddress] == 0) {
      poolToRibbonPoolTokenAddresses[_vaultAddress].remove(_ribbonVaultAddress);
    }
    return (shouldStop, sharesToWithdraw);
  }
}
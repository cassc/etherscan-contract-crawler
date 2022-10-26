// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";
import "./interfaces/IClearPoolDesk.sol";
import "./interfaces/IPoolMaster.sol";

/**
 * @title ClearPoolDesk
 * @notice NAV or statistics related to assets managed for ClearPoolDesk, the pool masters are contracts in ClearPool, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract ClearPoolDesk is IClearPoolDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  AlloyxConfig public config;
  EnumerableSet.AddressSet poolMasterAddresses;
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
   * @notice Get the token balance on one portfolio address
   * @param _address the address of managed portfolio
   */
  function balanceOfPortfolioToken(address _address) external view returns (uint256) {
    IManagedPortfolio managedPortfolio = IManagedPortfolio(_address);
    return managedPortfolio.balanceOf(address(this));
  }

  /**
   * @notice Get the Usdc value of the Clear Pool wallet
   */
  function getClearPoolWalletUsdcValue() external view override returns (uint256) {
    uint256 length = poolMasterAddresses.length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getClearPoolUsdcValueOfPoolMaster(poolMasterAddresses.at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the Usdc value of the Clear Pool wallet on one pool master address
   * @param _address the address of pool master
   */
  function getClearPoolUsdcValueOfPoolMaster(address _address) public view returns (uint256) {
    IPoolMaster poolMaster = IPoolMaster(_address);
    uint256 exchangeRate = poolMaster.getCurrentExchangeRate();
    uint256 balanceOfWallet = poolMaster.balanceOf(address(this));
    return balanceOfWallet.mul(exchangeRate).div(1e18);
  }

  /**
   * @notice Add pool master address to the list
   * @param _address the address of pool master
   */
  function addPoolMasterAddress(address _address) external onlyAdmin {
    require(!poolMasterAddresses.contains(_address), "the address already inside the list");
    IPoolMaster poolMaster = IPoolMaster(_address);
    require(
      poolMaster.balanceOf(address(this)) > 0,
      "the balance of the desk on the pool master should not be 0 before adding"
    );
    poolMasterAddresses.add(_address);
  }

  /**
   * @notice Remove pool master address to the list
   * @param _address the address of pool master
   */
  function removePoolMasterAddress(address _address) external onlyAdmin {
    require(poolMasterAddresses.contains(_address), "the address should be inside the list");
    IPoolMaster poolMaster = IPoolMaster(_address);
    require(
      poolMaster.balanceOf(address(this)) == 0,
      "the balance of the desk on the pool master should be 0 before removing"
    );
    poolMasterAddresses.remove(_address);
  }

  /**
   * @notice Deposit treasury USDC to ClearPool pool master
   * @param _address the address of pool master
   * @param _amount the amount to deposit
   */
  function provide(address _address, uint256 _amount) external onlyAdmin {
    IPoolMaster poolMaster = IPoolMaster(_address);
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(_address, _amount);
    poolMaster.provide(_amount);
    if (!poolMasterAddresses.contains(_address)) {
      poolMasterAddresses.add(_address);
    }
  }

  /**
   * @notice Withdraw USDC from ClearPool pool master
   * @param _address the address of pool master
   * @param _amount the amount to withdraw in pool master tokens
   */
  function redeem(address _address, uint256 _amount) external onlyAdmin returns (uint256) {
    IPoolMaster poolMaster = IPoolMaster(_address);
    poolMaster.redeem(_amount);
    uint256 usdcAmount = config.getUSDC().balanceOf(address(this));
    config.getUSDC().transfer(config.treasuryAddress(), usdcAmount);
    if (poolMaster.balanceOf(address(this)) == 0) {
      poolMasterAddresses.remove(_address);
    }
    return usdcAmount;
  }
}
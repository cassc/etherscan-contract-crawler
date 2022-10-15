// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";
import "./interfaces/IMapleDesk.sol";

/**
 * @title MapleDesk
 * @notice NAV or statistics related to assets managed for Maple
 * @author AlloyX
 */
contract MapleDesk is IMapleDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  AlloyxConfig public config;
  EnumerableSet.AddressSet poolAddresses;
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
   * @notice Get the token balance on one pool address
   * @param _address the address of pool
   */
  function balanceOfPoolToken(address _address) external view returns (uint256) {
    IPool pool = IPool(_address);
    return pool.balanceOf(address(this));
  }

  /**
   * @notice Get the Usdc value of the truefi wallet
   */
  function getMapleWalletUsdcValue() external view override returns (uint256) {
    uint256 length = poolAddresses.length();
    uint256 allBalance = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balance = getMapleWalletUsdcValueOfPool(poolAddresses.at(i));
      allBalance += balance;
    }
    return allBalance;
  }

  /**
   * @notice Get the Usdc value of the truefi wallet
   * @param _address the address of pool
   */
  function getMapleWalletUsdcValueOfPool(address _address) public view returns (uint256) {
    IPool pool = IPool(_address);
    uint256 loss = pool.recognizableLossesOf(address(this));
    uint256 interest = pool.withdrawableFundsOf(address(this));
    uint256 principalInUsdc = pool.balanceOf(address(this)).mul(10**6).div(
      10**pool.decimals()
    );
    return principalInUsdc.add(interest).sub(loss);
  }

  /**
   * @notice Add pool address to the list
   * @param _address the address of pool
   */
  function addPoolAddress(address _address) external onlyAdmin {
    require(!poolAddresses.contains(_address), "the address already inside the list");
    IPool pool = IPool(_address);
    require(
      pool.balanceOf(address(this)) > 0,
      "the balance of the desk on the pool should not be 0 before adding"
    );
    poolAddresses.add(_address);
  }

  /**
   * @notice Remove managed portfolio address to the list
   * @param _address the address of managed portfolio
   */
  function removeManagedPortfolioAddress(address _address) external onlyAdmin {
    require(poolAddresses.contains(_address), "the address should be inside the list");
    IPool pool = IPool(_address);
    require(
      pool.balanceOf(address(this)) == 0,
      "the balance of the desk on the pool should be 0 before removing"
    );
    poolAddresses.remove(_address);
  }

  /**
   * @notice Deposit treasury USDC to Maple pool
   * @param _address the address of pool
   * @param _amount the amount to deposit
   */
  function depositToMaple(address _address, uint256 _amount) external onlyAdmin {
    IPool pool = IPool(_address);
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(_address, _amount);
    pool.deposit(_amount);
    uint256 balance = pool.balanceOf(address(this));
    if (!poolAddresses.contains(_address)) {
      poolAddresses.add(_address);
    }
  }

  /**
   * @notice Withdraw USDC from Maple managed portfolio and deposit to treasury
   * @param _address the address of pool
   * @param _amount the amount to withdraw in USDC
   */
  function withdrawFromMaple(address _address, uint256 _amount)
    external
    onlyAdmin
    returns (uint256)
  {
    IPool pool = IPool(_address);
    pool.withdraw(_amount);
    uint256 usdcBalance = config.getUSDC().balanceOf(address(this));
    config.getUSDC().transfer(config.treasuryAddress(), usdcBalance);
    if (pool.balanceOf(address(this)) == 0) {
      poolAddresses.remove(_address);
    }
    return usdcBalance;
  }
}
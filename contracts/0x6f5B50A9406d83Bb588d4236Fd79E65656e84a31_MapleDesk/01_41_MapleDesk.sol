// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
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

  AlloyxConfig public config;
  using ConfigHelper for AlloyxConfig;
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
   * @notice Get the Usdc value of the truefi wallet
   */
  function getMapleWalletUsdcValue() external view override returns (uint256) {
    uint256 loss = config.getPool().recognizableLossesOf(config.treasuryAddress());
    uint256 interest = config.getPool().withdrawableFundsOf(config.treasuryAddress());
    uint256 principalInUsdc = config.getPool().balanceOf(config.treasuryAddress()).mul(10**6).div(
      10**18
    );
    return principalInUsdc.add(interest).sub(loss);
  }

  /**
   * @notice Deposit treasury USDC to Maple managed portfolio
   * @param _amount the amount to deposit
   */
  function depositToMaple(uint256 _amount) external onlyAdmin {
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(config.poolAddress(), _amount);
    config.getPool().deposit(_amount);
    uint256 balance = config.getPool().balanceOf(address(this));
    config.getManagedPortfolio().transfer(config.treasuryAddress(), balance);
  }

  /**
   * @notice Withdraw USDC from Maple managed portfolio and deposit to treasury
   * @param _amount the amount to withdraw
   */
  function withdrawFromMaple(uint256 _amount) external onlyAdmin returns (uint256) {
    uint256 amountInPool = _amount.mul(10**18).div(10**6);
    config.getTreasury().transferERC20(config.poolAddress(), address(this), amountInPool);
    config.getPool().withdraw(_amount);
    uint256 usdcBalance = config.getUSDC().balanceOf(address(this));
    config.getUSDC().transfer(config.treasuryAddress(), usdcBalance);
    return usdcBalance;
  }
}
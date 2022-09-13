// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/ITruefiDesk.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";

/**
 * @title TruefiDesk
 * @notice NAV or statistics related to assets managed for Truefi
 * @author AlloyX
 */
contract TruefiDesk is ITruefiDesk, AdminUpgradeable {
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
  function getTruefiWalletUsdcValue() external view override returns (uint256) {
    uint256 portfolioNav = config.getManagedPortfolio().value();
    uint256 totalSupply = config.getManagedPortfolio().totalSupply();
    uint256 balanceOfWallet = config.getManagedPortfolio().balanceOf(config.treasuryAddress());
    return balanceOfWallet.mul(portfolioNav).div(totalSupply);
  }

  /**
   * @notice Deposit treasury USDC to truefi managed portfolio
   * @param _amount the amount to deposit
   */
  function depositToTruefi(uint256 _amount) external onlyAdmin {
    bytes memory emptyData;
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(config.managedPortfolioAddress(), _amount);
    config.getManagedPortfolio().deposit(_amount, emptyData);
    uint256 balance = config.getManagedPortfolio().balanceOf(address(this));
    config.getManagedPortfolio().transfer(config.treasuryAddress(), balance);
  }

  /**
   * @notice Withdraw USDC from truefi managed portfolio and deposit to treasury
   * @param _amount the amount to withdraw in ManagedPortfolio tokens
   */
  function withdrawFromTruefi(uint256 _amount) external onlyAdmin returns (uint256) {
    config.getTreasury().transferERC20(config.managedPortfolioAddress(), address(this), _amount);
    bytes memory emptyData;
    uint256 usdcAmount = config.getManagedPortfolio().withdraw(_amount, emptyData);
    config.getUSDC().transfer(config.treasuryAddress(), usdcAmount);
    return usdcAmount;
  }
}
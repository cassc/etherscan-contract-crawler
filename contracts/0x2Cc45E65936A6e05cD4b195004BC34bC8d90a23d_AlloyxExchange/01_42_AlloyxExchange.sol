// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAlloyxExchange.sol";
import "./ConfigHelper.sol";
import "./AdminUpgradeable.sol";
import "./AlloyxConfig.sol";

/**
 * @title AlloyxExchange
 * @notice Contract to maintain the exchange information or key statistics of AlloyxTreasury
 * @author AlloyX
 */
contract AlloyxExchange is IAlloyxExchange, AdminUpgradeable {
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
   * @notice Alloy DURA Token Value in terms of USDC
   */
  function getTreasuryTotalBalanceInUsdc() public view override returns (uint256) {
    uint256 totalValue = config
      .getUSDC()
      .balanceOf(config.treasuryAddress())
      .add(getFiduBalanceInUsdc())
      .add(config.getGoldfinchDesk().getGoldFinchPoolTokenBalanceInUsdc())
      .add(config.getTruefiDesk().getTruefiWalletUsdcValue())
      .add(config.getClearPoolDesk().getClearPoolWalletUsdcValue())
      .add(config.getMapleDesk().getMapleWalletUsdcValue());
    return totalValue.sub(config.getTreasury().getAllUsdcFees());
  }

  /**
   * @notice Convert Alloyx DURA to USDC amount
   * @param _amount the amount of DURA token to convert to usdc
   */
  function alloyxDuraToUsdc(uint256 _amount) external view override returns (uint256) {
    uint256 alloyDuraTotalSupply = config.getDURA().totalSupply();
    uint256 totalValue = getTreasuryTotalBalanceInUsdc();
    return _amount.mul(totalValue).div(alloyDuraTotalSupply);
  }

  /**
   * @notice Convert USDC Amount to Alloyx DURA
   * @param _amount the amount of usdc to convert to DURA token
   */
  function usdcToAlloyxDura(uint256 _amount) external view override returns (uint256) {
    uint256 alloyDuraTotalSupply = config.getDURA().totalSupply();
    uint256 totalValue = getTreasuryTotalBalanceInUsdc();
    return _amount.mul(alloyDuraTotalSupply).div(totalValue);
  }

  /**
   * @notice Fidu Value in Vault in term of USDC
   */
  function getFiduBalanceInUsdc() public view returns (uint256) {
    return
      fiduToUsdc(
        config
          .getFIDU()
          .balanceOf(config.treasuryAddress())
          .mul(config.getSeniorPool().sharePrice())
          .div(fiduMantissa())
      );
  }

  /**
   * @notice Convert FIDU coins to USDC
   */
  function fiduToUsdc(uint256 amount) internal pure returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  /**
   * @notice Fidu mantissa with 18 decimals
   */
  function fiduMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  /**
   * @notice USDC mantissa with 6 decimals
   */
  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }
}
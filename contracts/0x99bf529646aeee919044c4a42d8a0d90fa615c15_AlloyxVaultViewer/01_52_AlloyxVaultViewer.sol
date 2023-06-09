// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../interfaces/IAlloyxVault.sol";

/**
 * @title AlloyxVaultViewer
 * @notice AlloyxVaultViewer gives visibility to vault state
 * @author AlloyX
 */
contract AlloyxVaultViewer is AdminUpgradeable {
  using ConfigHelper for AlloyxConfig;
  using SafeMath for uint256;

  AlloyxConfig public config;

  struct BackedStats {
    uint256 backedInUsdc;
    uint256 comfirmedInBacked;
    uint256 pendingInUsdc;
  }

  struct FluxStats {
    uint256 totalUsdc;
    uint256 totalFlux;
  }

  struct GoldfinchJuniorTokenStats {
    uint256 tokenId;
    uint256 usdcValue;
  }

  struct GoldfinchStats {
    GoldfinchJuniorStats juniorStats;
    GoldfinchSeniorStats seniorStats;
  }

  struct GoldfinchSeniorStats {
    uint256 usdcAmount;
    uint256 fiduBalance;
  }

  struct GoldfinchJuniorStats {
    uint256 totalUsdc;
    GoldfinchJuniorTokenStats[] stats;
  }

  struct TotalStats {
    uint256 totalUsdc;
    SinglePoolStats[] stats;
  }

  struct SinglePoolStats {
    uint256 usdcValue;
    uint256 tokenAmount;
    address poolAddress;
  }

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
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  function getBackedDeskStats(address _vaultAddress) external view returns (BackedStats memory) {
    return
      BackedStats(
        config.getBackedDesk().getBackedTokenValueInUsdc(_vaultAddress),
        config.getBackedDesk().getConfirmedBackedTokenAmount(_vaultAddress),
        config.getBackedDesk().getPendingVaultUsdcValue(_vaultAddress)
      );
  }

  function getClearPoolDeskStats(address _vaultAddress) external view returns (TotalStats memory) {
    address[] memory addresses = config.getClearPoolDesk().getClearPoolAddressesForVault(_vaultAddress);
    SinglePoolStats[] memory stats = new SinglePoolStats[](addresses.length);
    for (uint256 i = 0; i < addresses.length; i++) {
      stats[i] = SinglePoolStats(
        config.getClearPoolDesk().getClearPoolUsdcValueOfPoolMaster(_vaultAddress, addresses[i]),
        config.getClearPoolDesk().getClearPoolBalanceForVault(_vaultAddress, addresses[i]),
        addresses[i]
      );
    }
    return TotalStats(config.getClearPoolDesk().getClearPoolWalletUsdcValue(_vaultAddress), stats);
  }

  function getCredixDeskStats(address _vaultAddress) external view returns (uint256) {
    return config.getCredixDesk().getCredixWalletUsdcValue(_vaultAddress);
  }

  function getWalletDeskStats(address _vaultAddress) external view returns (uint256) {
    return config.getWalletDesk().getWalletUsdcValue(_vaultAddress);
  }

  function getFluxDeskStats(address _vaultAddress) external view returns (FluxStats memory) {
    return FluxStats(config.getFluxDesk().getFluxBalanceInUsdc(_vaultAddress), config.getFluxDesk().getFluxBalance(_vaultAddress));
  }

  function getMapleDeskStats(address _vaultAddress) external view returns (TotalStats memory) {
    address[] memory addresses = config.getMapleDesk().getMaplePoolAddressesForVault(_vaultAddress);
    SinglePoolStats[] memory stats = new SinglePoolStats[](addresses.length);
    for (uint256 i = 0; i < addresses.length; i++) {
      stats[i] = SinglePoolStats(
        config.getMapleDesk().getMapleWalletUsdcValueOfPool(_vaultAddress, addresses[i]),
        config.getMapleDesk().getMapleBalanceOfPool(_vaultAddress, addresses[i]),
        addresses[i]
      );
    }
    return TotalStats(config.getMapleDesk().getMapleWalletUsdcValue(_vaultAddress), stats);
  }

  function getRibbonDeskStats(address _vaultAddress) external view returns (TotalStats memory) {
    address[] memory addresses = config.getRibbonDesk().getRibbonVaultAddressesForAlloyxVault(_vaultAddress);
    SinglePoolStats[] memory stats = new SinglePoolStats[](addresses.length);
    for (uint256 i = 0; i < addresses.length; i++) {
      stats[i] = SinglePoolStats(
        config.getRibbonDesk().getRibbonUsdcValueOfVault(_vaultAddress, addresses[i]),
        config.getRibbonDesk().getRibbonVaultShareForAlloyxVault(_vaultAddress, addresses[i]),
        addresses[i]
      );
    }
    return TotalStats(config.getRibbonDesk().getRibbonWalletUsdcValue(_vaultAddress), stats);
  }

  function getRibbonLendDeskStats(address _vaultAddress) external view returns (TotalStats memory) {
    address[] memory addresses = config.getRibbonLendDesk().getRibbonLendVaultAddressesForAlloyxVault(_vaultAddress);
    SinglePoolStats[] memory stats = new SinglePoolStats[](addresses.length);
    for (uint256 i = 0; i < addresses.length; i++) {
      stats[i] = SinglePoolStats(
        config.getRibbonLendDesk().getRibbonLendUsdcValueOfPoolMaster(_vaultAddress, addresses[i]),
        config.getRibbonLendDesk().getRibbonLendVaultShareForAlloyxVault(_vaultAddress, addresses[i]),
        addresses[i]
      );
    }
    return TotalStats(config.getRibbonLendDesk().getRibbonLendWalletUsdcValue(_vaultAddress), stats);
  }

  function getTruefiDeskStats(address _vaultAddress) external view returns (TotalStats memory) {
    address[] memory addresses = config.getTruefiDesk().getTruefiVaultAddressesForAlloyxVault(_vaultAddress);
    SinglePoolStats[] memory stats = new SinglePoolStats[](addresses.length);
    for (uint256 i = 0; i < addresses.length; i++) {
      stats[i] = SinglePoolStats(
        config.getTruefiDesk().getTruefiWalletUsdcValueOfPortfolio(_vaultAddress, addresses[i]),
        config.getTruefiDesk().getTruefiVaultShareForAlloyxVault(_vaultAddress, addresses[i]),
        addresses[i]
      );
    }
    return TotalStats(config.getTruefiDesk().getTruefiWalletUsdcValue(_vaultAddress), stats);
  }

  function getOpenEdenDeskStats(address _vaultAddress) external view returns (TotalStats memory) {
    address[] memory addresses = config.getOpenEdenDesk().getOpenEdenVaultAddressesForAlloyxVault(_vaultAddress);
    SinglePoolStats[] memory stats = new SinglePoolStats[](addresses.length);
    for (uint256 i = 0; i < addresses.length; i++) {
      stats[i] = SinglePoolStats(
        config.getOpenEdenDesk().getOpenEdenWalletUsdcValueOfPortfolio(_vaultAddress, addresses[i]),
        config.getOpenEdenDesk().getOpenEdenVaultShareForAlloyxVault(_vaultAddress, addresses[i]),
        addresses[i]
      );
    }
    return TotalStats(config.getOpenEdenDesk().getOpenEdenWalletUsdcValue(_vaultAddress), stats);
  }

  function getGoldfinchDeskStats(address _vaultAddress) external view returns (GoldfinchStats memory) {
    uint256[] memory ids = config.getGoldfinchDesk().getGoldFinchPoolTokenIds(_vaultAddress);
    GoldfinchJuniorTokenStats[] memory stats = new GoldfinchJuniorTokenStats[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      stats[i] = GoldfinchJuniorTokenStats(ids[i], config.getGoldfinchDesk().getJuniorTokenValue(ids[i]));
    }
    GoldfinchJuniorStats memory juniorStats = GoldfinchJuniorStats(config.getGoldfinchDesk().getGoldFinchPoolTokenBalanceInUsdc(_vaultAddress), stats);
    GoldfinchSeniorStats memory seniorStats = GoldfinchSeniorStats(config.getGoldfinchDesk().getFiduBalanceInUsdc(_vaultAddress), config.getGoldfinchDesk().getFiduBalance(_vaultAddress));
    return GoldfinchStats(juniorStats, seniorStats);
  }
}
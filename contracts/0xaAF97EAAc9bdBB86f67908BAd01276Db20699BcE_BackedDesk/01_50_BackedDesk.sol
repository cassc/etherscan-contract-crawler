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
 * @title BackedDesk
 * @notice NAV or statistics related to assets managed for Backed, the managed portfolios are contracts in Backed, in here, we take portfolio with USDC as base token
 * @author AlloyX
 */
contract BackedDesk is IBackedDesk, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  AlloyxConfig public config;
  mapping(address => uint256) public vaultToReservedBackedTokens;
  mapping(address => uint256) public vaultToAvailableBackedTokens;
  mapping(address => uint256) public vaultToReservedUsdc;
  mapping(address => uint256) public vaultToAvailableUsdc;

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
   * @notice Deposit USDC to the desk and prepare for being taken to invest in Backed
   * @param _vaultAddress the address of vault
   * @param _amount the amount of USDC
   */
  function deposit(address _vaultAddress, uint256 _amount) external override onlyOperator {
    vaultToReservedUsdc[_vaultAddress] = vaultToReservedUsdc[_vaultAddress].add(_amount);
    vaultToAvailableUsdc[_vaultAddress] = vaultToAvailableUsdc[_vaultAddress].add(_amount);
  }

  /**
   * @notice Withdraw all available USDC from the vault to admin to deposit to Backed protocol
   * @param _vaultAddress the address of vault
   */
  function withdrawToDepositToBacked(address _vaultAddress) external onlyAdmin {
    require(vaultToAvailableUsdc[_vaultAddress] > 0, "the vault has no available USDC");
    transferERC20(config.usdcAddress(), msg.sender, vaultToAvailableUsdc[_vaultAddress]);
    vaultToAvailableUsdc[_vaultAddress] = 0;
  }

  /**
   * @notice Deposit Backed Token to the desk under the vault address
   * @param _vaultAddress the address of vault
   * @param _backedAmount the amount of backed token getting in
   * @param _usdcAmount the amount of USDC to exchange the backed token
   */
  function depositBackedTokenToVault(
    address _vaultAddress,
    uint256 _backedAmount,
    uint256 _usdcAmount
  ) external onlyAdmin {
    transferERC20From(msg.sender, config.backedTokenAddress(), address(this), _backedAmount);
    vaultToReservedBackedTokens[_vaultAddress] = vaultToReservedBackedTokens[_vaultAddress].add(_backedAmount);
    vaultToAvailableBackedTokens[_vaultAddress] = vaultToAvailableBackedTokens[_vaultAddress].add(_backedAmount);
    vaultToReservedUsdc[_vaultAddress] = vaultToReservedUsdc[_vaultAddress].sub(_usdcAmount);
  }

  /**
   * @notice Withdraw Backed Token from the desk under the vault address
   * @param _vaultAddress the address of vault
   * @param _backedAmount the amount of backed token getting out
   */
  function withdrawBackedTokeFromVault(address _vaultAddress, uint256 _backedAmount) external onlyAdmin {
    require(vaultToAvailableBackedTokens[_vaultAddress] >= _backedAmount, "the vault has no available Backed Token");
    transferERC20(config.backedTokenAddress(), msg.sender, _backedAmount);
    vaultToAvailableBackedTokens[_vaultAddress] = vaultToAvailableBackedTokens[_vaultAddress].sub(_backedAmount);
  }

  /**
   * @notice Deposit USDC after selling Backed Token
   * @param _vaultAddress the address of vault
   * @param _backedAmount the amount of backed token taken out
   * @param _usdcAmount the amount of USDC to exchange the backed token
   */
  function depositUsdcToVault(
    address _vaultAddress,
    uint256 _backedAmount,
    uint256 _usdcAmount
  ) external onlyAdmin {
    transferERC20From(msg.sender, config.usdcAddress(), _vaultAddress, _usdcAmount);
    vaultToReservedBackedTokens[_vaultAddress] = vaultToReservedBackedTokens[_vaultAddress].sub(_backedAmount);
  }

  /**
   * @notice Deposit USDC to the desk and prepare for being taken to invest in Backed
   * @param _vaultAddress the address of vault
   */
  function getBackedTokenValueInUsdc(address _vaultAddress) external view override returns (uint256) {
    uint256 realBackedTokenValue = vaultToReservedBackedTokens[_vaultAddress]
      .mul(uint256(config.getBackedOracle().latestAnswer()))
      .mul(10**config.getUSDC().decimals())
      .div(10**config.getBackedOracle().decimals())
      .div(10**config.getBackedToken().decimals());
    uint256 placeHolderUsdcValue = vaultToReservedUsdc[_vaultAddress];
    return placeHolderUsdcValue.add(realBackedTokenValue);
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

  /**
   * @notice Transfer certain amount token of certain address to some other account, internal
   * @param _from the address to transfer from
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20From(
    address _from,
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) public onlyAdmin {
    IERC20Upgradeable(_tokenAddress).safeTransferFrom(_from, _account, _amount);
  }
}
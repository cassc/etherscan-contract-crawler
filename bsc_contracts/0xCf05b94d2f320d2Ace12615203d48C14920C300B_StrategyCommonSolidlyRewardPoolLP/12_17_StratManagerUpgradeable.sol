// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract StratManagerUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {
  /**
   * @dev Beefy Contracts:
   * {keeper} - Address to manage a few lower risk features of the strat
   * {strategist} - Address of the strategy author/deployer where strategist fee will go.
   * {vault} - Address of the vault that controls the strategy's funds.
   * {dystRouter} - Address of exchange to execute swaps.
   */
  address public keeper;
  address public strategist;
  address public dystRouter;
  address public vault;
  address public feeRecipient1;
  address public feeRecipient2;

  /**
   * @dev Initializes the base strategy.
   * @param _keeper address to use as alternative owner.
   * @param _strategist address where strategist fees go.
   * @param _dystRouter router to use for swaps
   * @param _vault address of parent vault.
   * @param _feeRecipient address where to send Beefy's fees.
   */
  function __StratManager_init(
    address _keeper,
    address _strategist,
    address _dystRouter,
    address _vault,
    address _feeRecipient
  ) internal initializer {
    __Ownable_init_unchained();
    __Pausable_init_unchained();
    __StratManager_init_unchained(_keeper, _strategist, _dystRouter, _vault, _feeRecipient);
  }

  function __StratManager_init_unchained(
    address _keeper,
    address _strategist,
    address _dystRouter,
    address _vault,
    address _feeRecipient
  ) internal initializer {
    keeper = _keeper;
    strategist = _strategist;
    dystRouter = _dystRouter;
    vault = _vault;
    feeRecipient1 = _feeRecipient;
    feeRecipient2 = _feeRecipient;
  }

  // checks that caller is either owner or keeper.
  modifier onlyManager() {
    require(msg.sender == owner() || msg.sender == keeper, "!manager");
    _;
  }

  /**
   * @dev Updates address of the strat keeper.
   * @param _keeper new keeper address.
   */
  function setKeeper(address _keeper) external onlyManager {
    keeper = _keeper;
  }

  /**
   * @dev Updates address where strategist fee earnings will go.
   * @param _strategist new strategist address.
   */
  function setStrategist(address _strategist) external {
    require(msg.sender == strategist, "!strategist");
    strategist = _strategist;
  }

  /**
   * @dev Updates router that will be used for swaps.
   * @param _dystRouter new dystRouter address.
   */
  function setDystRouter(address _dystRouter) external onlyOwner {
    dystRouter = _dystRouter;
  }

  /**
   * @dev Updates parent vault.
   * @param _vault new vault address.
   */
  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }

  /**
   * @dev Updates beefy fee recipient.
   * @param _feeRecipient new beefy fee recipient address.
   */
  function setFeeRecipient1(address _feeRecipient) external onlyOwner {
    feeRecipient1 = _feeRecipient;
  }

  /**
   * @dev Updates beefy fee recipient 2.
   * @param _feeRecipient2 new beefy fee recipient address.
   */
  function setFeeRecipient2(address _feeRecipient2) external onlyOwner {
    feeRecipient2 = _feeRecipient2;
  }

  /**
   * @dev Function to synchronize balances before new user deposit.
   * Can be overridden in the strategy.
   */
  function beforeDeposit() external virtual {}
}
//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {Harvestable} from "./Harvestable.sol";
import {IWarLocker} from "interfaces/IWarLocker.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Owner} from "utils/Owner.sol";
import {Errors} from "utils/Errors.sol";
import {IWarRedeemModule} from "interfaces/IWarRedeemModule.sol";
import {WarMinter} from "src/Minter.sol";

/**
 * @title Warlord Base Locker contract
 * @author Paladin
 * @notice Base implementation for Locker contracts
 */
abstract contract WarBaseLocker is IWarLocker, Pausable, Owner, ReentrancyGuard, Harvestable {
  /**
   * @notice Address of the voting power delegate
   */
  address public delegate;
  /**
   * @notice Address of the Redeem Module contract
   */
  address public redeemModule;
  /**
   * @notice Address of the Controller contract
   */
  address public controller;
  /**
   * @notice Address of the Minter contract
   */
  address public warMinter;
  /**
   * @notice Is the contract shutdown
   */
  bool public isShutdown;

  /**
   * @notice Event emitted when the Controller is set
   */
  event SetController(address newController);
  /**
   * @notice Event emitted when the Redeem Module is set
   */
  event SetRedeemModule(address newRedeemModule);
  /**
   * @notice Event emitted when the delegate is updated
   */
  event SetDelegate(address newDelegatee);
  /**
   * @notice Event emitted when the Locker is shutdown
   */
  event Shutdown();

  // Constructor

  constructor(address _controller, address _redeemModule, address _warMinter, address _delegatee) {
    if (_controller == address(0) || _redeemModule == address(0) || _warMinter == address(0)) {
      revert Errors.ZeroAddress();
    }
    warMinter = _warMinter;
    controller = _controller;
    redeemModule = _redeemModule;
    delegate = _delegatee;
  }

  /**
   * @notice Returns the current total amount of locked tokens for this Locker
   */
  function getCurrentLockedTokens() external view virtual returns (uint256);

  /**
   * @notice Updates the Controller contract
   * @param _controller Address of the Controller contract
   */
  function setController(address _controller) external onlyOwner {
    if (_controller == address(0)) revert Errors.ZeroAddress();
    if (_controller == controller) revert Errors.AlreadySet();
    controller = _controller;

    emit SetController(_controller);
  }

  /**
   * @notice Updates the Redeem Module contract
   * @param _redeemModule Address of the Redeem Module contract
   */
  function setRedeemModule(address _redeemModule) external onlyOwner {
    if (_redeemModule == address(0)) revert Errors.ZeroAddress();
    if (_redeemModule == address(redeemModule)) revert Errors.AlreadySet();
    redeemModule = _redeemModule;

    emit SetRedeemModule(_redeemModule);
  }

  /**
   * @dev Updates the Delegatee & delegates the voting power
   * @param _delegatee Address of the delegatee
   */
  function _setDelegate(address _delegatee) internal virtual;

  /**
   * @notice Updates the Delegatee & delegates the voting power
   * @param _delegatee Address of the delegatee
   */
  function setDelegate(address _delegatee) external onlyOwner {
    delegate = _delegatee;
    _setDelegate(_delegatee);

    emit SetDelegate(_delegatee);
  }

  /**
   * @dev Locks the tokens in the vlToken contract
   * @param amount Amount to lock
   */
  function _lock(uint256 amount) internal virtual;

  /**
   * @notice Locks the tokens in the vlToken contract
   * @param amount Amount to lock
   */
  function lock(uint256 amount) external nonReentrant whenNotPaused {
    if (warMinter != msg.sender) revert Errors.CallerNotAllowed();
    if (amount == 0) revert Errors.ZeroValue();
    _lock(amount);
  }

  /**
   * @dev Processes the unlock of tokens
   */
  function _processUnlock() internal virtual;

  /**
   * @notice Processes the unlock of tokens
   */
  function processUnlock() external nonReentrant whenNotPaused {
    _processUnlock();
  }

  /**
   * @dev Harvest rewards & send them to the Controller
   */
  function _harvest() internal virtual;

  /**
   * @notice Harvest rewards
   */
  function harvest() external whenNotPaused {
    _harvest();
  }

  /**
   * @dev Migrates the tokens hold by this contract to another address (& unlocks everything that can be unlocked)
   * @param receiver Address to receive the migrated tokens
   */
  function _migrate(address receiver) internal virtual;

  /**
   * @notice Migrates the tokens hold by this contract to another address
   * @param receiver Address to receive the migrated tokens
   */
  function migrate(address receiver) external nonReentrant onlyOwner whenPaused {
    if (receiver == address(0)) revert Errors.ZeroAddress();
    _migrate(receiver);
  }

  /**
   * @notice Pause the contract
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause the contract
   */
  function unpause() external onlyOwner {
    if (isShutdown) revert Errors.LockerShutdown();
    _unpause();
  }

  /**
   * @notice Shutdowns the contract
   */
  function shutdown() external onlyOwner whenPaused {
    isShutdown = true;

    emit Shutdown();
  }
}
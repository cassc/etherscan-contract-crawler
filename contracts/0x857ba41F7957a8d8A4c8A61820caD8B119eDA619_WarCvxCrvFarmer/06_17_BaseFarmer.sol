//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {Harvestable} from "./Harvestable.sol";
import {Owner} from "utils/Owner.sol";
import {Errors} from "utils/Errors.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";
import {IFarmer} from "interfaces/IFarmer.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

/**
 * @title Warlord Base Farmer contract
 * @author Paladin
 * @notice Base implementation for Farmer contracts
 */
abstract contract WarBaseFarmer is IFarmer, Owner, Pausable, ReentrancyGuard, Harvestable {
  /**
   * @notice Address of the Controller contract
   */
  address public controller;
  /**
   * @notice Address of the Staker contract
   */
  address public warStaker;

  /**
   * @notice Current index for the token
   */
  uint256 internal _index;

  /**
   * @notice Event emitted when the Controller is set
   */
  event SetController(address controller);
  /**
   * @notice Event emitted when the Staker is set
   */
  event SetWarStaker(address warStaker);
  /**
   * @notice Event emitted when tokens are staked
   */
  event Staked(uint256 amount);

  // Modifiers

  /**
   * @notice Checks the caller is the Controller
   */
  modifier onlyController() {
    if (controller != msg.sender) revert Errors.CallerNotAllowed();
    _;
  }

  /**
   * @notice Checks the caller is the Staker
   */
  modifier onlyWarStaker() {
    if (warStaker != msg.sender) revert Errors.CallerNotAllowed();
    _;
  }

  // Constructor

  constructor(address _controller, address _warStaker) {
    if (_controller == address(0) || _warStaker == address(0)) revert Errors.ZeroAddress();
    controller = _controller;
    warStaker = _warStaker;
  }

  /**
   * @dev Checks if the token is supported by the Farmer
   * @param _token Address of the token to check
   * @return bool : True if the token is supported
   */
  function _isTokenSupported(address _token) internal virtual returns (bool);

  /**
   * @dev Stakes the given token (deposits beforehand if needed)
   * @param _token Address of the token to stake
   * @param _amount Amount to stake
   * @return uint256 : Amount staked
   */
  function _stake(address _token, uint256 _amount) internal virtual returns (uint256);

  /**
   * @notice Stakes the given token
   * @param _token Address of the token to stake
   * @param _amount Amount to stake
   */
  function stake(address _token, uint256 _amount) external nonReentrant onlyController whenNotPaused {
    if (!_isTokenSupported(_token)) revert Errors.IncorrectToken();
    if (_amount == 0) revert Errors.ZeroValue();

    // Staked amount may change from initial argument when wrapping BAL into auraBAL
    uint256 amountStaked = _stake(_token, _amount);

    emit Staked(amountStaked);
  }

  /**
   * @dev Harvests rewards from the staking contract & sends them to the Controller
   */
  function _harvest() internal virtual;

  /**
   * @notice Harvests rewards from the staking contract
   */
  function harvest() external nonReentrant whenNotPaused {
    _harvest();
  }

  /**
   * @notice Returns the current reward index for the Staker distribution
   * @return uint256 : current index
   */
  function getCurrentIndex() external view returns (uint256) {
    return _index;
  }

  /**
   * @dev Returns the balance of tokens staked by this contract in the staking contract
   * @return uint256 : staked balance for this contract
   */
  function _stakedBalance() internal virtual returns (uint256);

  /**
   * @dev Withdraws tokens and sends them to the receiver
   * @param receiver Address to receive the tokens
   * @param amount Amount to send
   */
  function _sendTokens(address receiver, uint256 amount) internal virtual;

  /**
   * @notice Sends them to the receiver
   * @param receiver Address to receive the tokens
   * @param amount Amount to send
   */
  function sendTokens(address receiver, uint256 amount) external nonReentrant onlyWarStaker whenNotPaused {
    if (receiver == address(0)) revert Errors.ZeroAddress();
    if (amount == 0) revert Errors.ZeroValue();
    if (_stakedBalance() < amount) revert Errors.UnstakingMoreThanBalance();

    _sendTokens(receiver, amount);
  }

  /**
   * @dev Withdraws & migrates the tokens hold by this contract to another address
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

    // Harvest and send rewards to the controller
    _harvest();
  }

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
   * @notice Updates the Staked contract
   * @param _warStaker Address of the Staked contract
   */
  function setWarStaker(address _warStaker) external onlyOwner {
    if (_warStaker == address(0)) revert Errors.ZeroAddress();
    if (_warStaker == warStaker) revert Errors.AlreadySet();
    warStaker = _warStaker;

    emit SetWarStaker(_warStaker);
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
    _unpause();
  }
}
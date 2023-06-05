//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {Owner} from "utils/Owner.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Errors} from "utils/Errors.sol";
import {IStaker} from "interfaces/IStaker.sol";
import {IMinter} from "interfaces/IMinter.sol";

/**
 * @title Warlord Zap contract
 * @author Paladin
 * @notice Zap to mint WAR & stake it directly
 */
contract WarZap is ReentrancyGuard, Pausable, Owner {
  using SafeERC20 for IERC20;

  /**
   * @notice Address of the WAR token
   */
  IERC20 public immutable warToken;
  /**
   * @notice Address of the Minter contract
   */
  IMinter public immutable minter;
  /**
   * @notice Address of the Staker contract
   */
  IStaker public immutable staker;

  /**
   * @notice Event emitted when zapping in
   */
  event Zap(address indexed sender, address indexed receiver, uint256 stakedAmount);

  // Constructor
  constructor(address _minter, address _staker, address _warToken) {
    if (_staker == address(0) || _minter == address(0) || _warToken == address(0)) revert Errors.ZeroAddress();
    staker = IStaker(_staker);
    minter = IMinter(_minter);
    warToken = IERC20(_warToken);

    IERC20(_warToken).safeApprove(_staker, type(uint256).max);
  }

  /**
   * @notice Zaps a given amount of tokens to mint WAR and stake it
   * @param token Address of the token to deposit
   * @param amount Amount to deposit
   * @param receiver Address to stake for
   * @return uint256 : Amount of WAR staked
   */
  function zap(address token, uint256 amount, address receiver) external nonReentrant whenNotPaused returns (uint256) {
    if (amount == 0) revert Errors.ZeroValue();
    if (token == address(0) || receiver == address(0)) revert Errors.ZeroAddress();

    uint256 prevBalance = IERC20(warToken).balanceOf(address(this));

    // Pull the token
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    // Mint WAR
    IERC20(token).safeIncreaseAllowance(address(minter), amount);
    minter.mint(token, amount);

    uint256 mintedAmount = IERC20(warToken).balanceOf(address(this)) - prevBalance;

    // Stake the WAR tokens for the receiver
    uint256 stakedAmount = staker.stake(mintedAmount, receiver);

    emit Zap(msg.sender, receiver, stakedAmount);

    return stakedAmount;
  }

  /**
   * @notice Zaps given amounts of tokens to mint WAR and stake it
   * @param vlTokens List of token addresses to deposit
   * @param amounts Amounts to deposit for each token
   * @param receiver Address to stake for
   * @return uint256 : Amount of WAR staked
   */
  function zapMultiple(address[] calldata vlTokens, uint256[] calldata amounts, address receiver)
    external
    nonReentrant
    whenNotPaused
    returns (uint256)
  {
    if (receiver == address(0)) revert Errors.ZeroAddress();
    uint256 length = vlTokens.length;
    if (length != amounts.length) revert Errors.DifferentSizeArrays(length, amounts.length);
    if (length == 0) revert Errors.EmptyArray();

    uint256 prevBalance = IERC20(warToken).balanceOf(address(this));

    // for each token in the list
    for (uint256 i; i < length;) {
      address token = vlTokens[i];
      uint256 amount = amounts[i];
      if (amount == 0) revert Errors.ZeroValue();
      if (token == address(0)) revert Errors.ZeroAddress();

      // Pull the token
      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

      // Mint WAR
      IERC20(token).safeIncreaseAllowance(address(minter), amount);
      minter.mint(token, amount);

      unchecked {
        i++;
      }
    }

    // Get the total amount of WAR minted
    uint256 mintedAmount = IERC20(warToken).balanceOf(address(this)) - prevBalance;

    // Stake the WAR tokens for the receiver
    uint256 stakedAmount = staker.stake(mintedAmount, receiver);

    emit Zap(msg.sender, receiver, stakedAmount);

    return stakedAmount;
  }

  // Admin functions

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

  /**
   * @notice Recover ERC2O tokens in the contract
   * @dev Recover ERC2O tokens in the contract
   * @param token Address of the ERC2O token
   * @return bool: success
   */
  function recoverERC20(address token) external onlyOwner returns (bool) {
    if (token == address(0)) revert Errors.ZeroAddress();
    uint256 amount = IERC20(token).balanceOf(address(this));
    if (amount == 0) revert Errors.ZeroValue();

    IERC20(token).safeTransfer(owner(), amount);

    return true;
  }
}
//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {WarToken} from "./Token.sol";
import {IWarLocker} from "interfaces/IWarLocker.sol";
import {IRatios} from "interfaces/IRatios.sol";
import {Owner} from "utils/Owner.sol";
import {Errors} from "utils/Errors.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

/**
 * @title Warlord Minter contract
 * @author Paladin
 * @notice Receives vlToken to deposit in Lockers and mints WAR
 */
contract WarMinter is Owner, ReentrancyGuard {
  using SafeERC20 for IERC20;

  /**
   * @notice WAR token contract
   */
  WarToken public immutable war;
  /**
   * @notice Address of the contract calculating the mint amounts
   */
  IRatios public ratios;
  /**
   * @notice Address of the Locker set for each token
   */
  mapping(address => address) public lockers;

  /**
   * @notice Event emitted when the Ratio contract is updated
   */
  event MintRatioUpdated(address oldMintRatio, address newMintRatio);

  // Constructor

  constructor(address _war, address _ratios) {
    if (_war == address(0) || _ratios == address(0)) revert Errors.ZeroAddress();
    war = WarToken(_war);
    ratios = IRatios(_ratios);
  }

  /**
   * @notice Sets a new Locker for a given token
   * @param vlToken Address of the token
   * @param warLocker Address of the Locker
   */
  function setLocker(address vlToken, address warLocker) external onlyOwner {
    if (vlToken == address(0) || warLocker == address(0)) revert Errors.ZeroAddress();
    address expectedToken = IWarLocker(warLocker).token();
    if (expectedToken != vlToken) revert Errors.MismatchingLocker(expectedToken, vlToken);
    lockers[vlToken] = warLocker;
  }

  /**
   * @notice Mints WAR token based of the amount of token deposited
   * @param vlToken Address of the token to deposit
   * @param amount Amount to deposit
   */
  function mint(address vlToken, uint256 amount) external nonReentrant {
    _mint(vlToken, amount, msg.sender);
  }

  /**
   * @notice Mints WAR token based of the amount of token deposited, mints for the given receiver
   * @param vlToken Address of the token to deposit
   * @param amount Amount to deposit
   * @param receiver Address to receive the minted WAR
   */
  function mint(address vlToken, uint256 amount, address receiver) external nonReentrant {
    _mint(vlToken, amount, receiver);
  }

  /**
   * @dev Pulls tokens to deposit in the associated Locker & mints WAR based on the deposited amount
   * @param vlToken Address of the token to deposit
   * @param amount Amount to deposit
   * @param receiver Address to receive the minted WAR
   */
  function _mint(address vlToken, uint256 amount, address receiver) internal {
    if (amount == 0) revert Errors.ZeroValue();
    if (vlToken == address(0) || receiver == address(0)) revert Errors.ZeroAddress();
    if (lockers[vlToken] == address(0)) revert Errors.NoWarLocker();

    // Load the correct Locker contract
    IWarLocker locker = IWarLocker(lockers[vlToken]);

    // Pull the tokens, and deposit them in the Locker
    IERC20(vlToken).safeTransferFrom(msg.sender, address(this), amount);
    if (IERC20(vlToken).allowance(address(this), address(locker)) != 0) IERC20(vlToken).safeApprove(address(locker), 0);
    IERC20(vlToken).safeIncreaseAllowance(address(locker), amount);
    locker.lock(amount);

    // Get the amount of WAR to mint for the deposited amount
    uint256 mintAmount = ratios.getMintAmount(vlToken, amount);
    if (mintAmount == 0) revert Errors.ZeroMintAmount();

    // Mint the WAR to the receiver
    war.mint(receiver, mintAmount);
  }

  /**
   * @dev Pulls multiple tokens to deposit in the associated Locker & mints WAR based on the deposited amounts
   * @param vlTokens List of address of tokens to deposit
   * @param amounts List of amounts to deposit
   * @param receiver Address to receive the minted WAR
   */
  function _mintMultiple(address[] calldata vlTokens, uint256[] calldata amounts, address receiver) internal {
    if (vlTokens.length != amounts.length) revert Errors.DifferentSizeArrays(vlTokens.length, amounts.length);
    if (vlTokens.length == 0) revert Errors.EmptyArray();
    uint256 length = vlTokens.length;
    for (uint256 i; i < length;) {
      _mint(vlTokens[i], amounts[i], receiver);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Mints WAR token based of the amounts of tokens deposited
   * @param vlTokens List of address of tokens to deposit
   * @param amounts List of amounts to deposit
   * @param receiver Address to receive the minted WAR
   */
  function mintMultiple(address[] calldata vlTokens, uint256[] calldata amounts, address receiver)
    external
    nonReentrant
  {
    _mintMultiple(vlTokens, amounts, receiver);
  }

  /**
   * @notice Mints WAR token based of the amounts of tokens deposited
   * @param vlTokens List of address of tokens to deposit
   * @param amounts List of amounts to deposit
   */
  function mintMultiple(address[] calldata vlTokens, uint256[] calldata amounts) external nonReentrant {
    _mintMultiple(vlTokens, amounts, msg.sender);
  }

  /**
   * @notice Sets the Ratio contract address
   * @param newRatios Address of the new Ratio contract
   */
  function setRatios(address newRatios) external onlyOwner {
    if (newRatios == address(0)) revert Errors.ZeroAddress();

    address oldRatios = address(ratios);
    ratios = IRatios(newRatios);

    emit MintRatioUpdated(oldRatios, newRatios);
  }
}
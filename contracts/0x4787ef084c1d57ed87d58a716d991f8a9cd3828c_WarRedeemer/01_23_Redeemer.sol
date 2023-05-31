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
import {WarToken} from "./Token.sol";
import {IRatios} from "interfaces/IRatios.sol";
import {IWarRedeemModule} from "interfaces/IWarRedeemModule.sol";
import {IWarLocker} from "interfaces/IWarLocker.sol";

/**
 * @title Warlord contract to redeem vlTokens by burning WAR
 * @author Paladin
 * @notice Redeem vlTokens against WAR & burn WAR
 */
contract WarRedeemer is IWarRedeemModule, ReentrancyGuard, Pausable, Owner {
  using SafeERC20 for IERC20;

  // Constants

  /**
   * @notice 1e18 scale
   */
  uint256 public constant UNIT = 1e18;
  /**
   * @notice Max BPS value (100%)
   */
  uint256 public constant MAX_BPS = 10_000;

  // Struct

  /**
   * @notice TokenIndex struct
   *   queueIndex: current index for the queue
   *   redeemIndex: current index for redeems
   */
  struct TokenIndex {
    uint256 queueIndex;
    uint256 redeemIndex;
  }

  /**
   * @notice RedeemTicket struct
   *   amount: amount of tokens to redeem
   *   redeemIndex: index at which the redeem is possible
   *   token: address of the token to redeem
   *   redeemed: true if redeemed
   */
  struct RedeemTicket {
    uint256 id;
    uint256 amount;
    uint256 redeemIndex;
    address token;
    bool redeemed;
  }

  /**
   * @notice TokenWeight struct
   *   token: token which backs the war token
   *   weight: the percentage of the backing in BPS
   */
  struct TokenWeight {
    address token;
    uint256 weight;
  }

  // Storage

  /**
   * @notice Address of the WAR token
   */
  address public immutable war;

  /**
   * @notice Address of the contract calculating the burn amounts
   */
  IRatios public ratios;

  /**
   * @notice Address of receive the redeem fees
   */
  address public feeReceiver;

  /**
   * @notice Addresses of the tokens in the lockers
   */
  address[] public tokens;

  /**
   * @notice Address of the Locker set for each token
   */
  // token => Locker
  mapping(address => address) public lockers;
  /**
   * @notice Address of the token for each Locker
   */
  // Locker => token
  mapping(address => address) public lockerTokens;

  /**
   * @notice Ratio of fees in BPS taken when redeeming
   */
  uint256 public redeemFee;

  /**
   * @notice Indexes struct for each token
   */
  mapping(address => TokenIndex) public tokenIndexes;

  /**
   * @notice List of Redeem tickets for each token for each user
   */
  // user => token => UserIndexes
  mapping(address => RedeemTicket[]) public userRedeems;

  // Events

  /**
   * @notice Event emitted when a Redeem ticket is created
   */
  event NewRedeemTicket(address indexed token, address indexed user, uint256 id, uint256 amount, uint256 redeemIndex);

  /**
   * @notice Event emitted when a Redeem ticket is redeemed
   */
  event Redeemed(address indexed token, address indexed user, address receiver, uint256 indexed ticketNumber);

  /**
   * @notice Event emitted when setting a Locker for a token
   */
  event SetWarLocker(address indexed token, address indexed locker);

  /**
   * @notice Event emitted when the redeem fee is updated
   */
  event RedeemFeeUpdated(uint256 oldRedeemFee, uint256 newRedeemFee);
  /**
   * @notice Event emitted when the Ratio contract is updated
   */
  event MintRatioUpdated(address oldMintRatio, address newMintRatio);
  /**
   * @notice Event emitted when the fee receiver is updated
   */
  event FeeReceiverUpdated(address oldFeeReceiver, address newFeeReceiver);

  // Constructor

  constructor(address _war, address _ratios, address _feeReceiver, uint256 _redeemFee) {
    if (_war == address(0) || _ratios == address(0) || _feeReceiver == address(0)) revert Errors.ZeroAddress();
    if (_redeemFee == 0 || _redeemFee > 1000) revert Errors.InvalidParameter();

    war = _war;
    ratios = IRatios(_ratios);
    feeReceiver = _feeReceiver;
    redeemFee = _redeemFee;
  }

  // View Functions

  /**
   * @notice Returns the amount queued for withdrawal for a given token
   * @param token Address of the token
   * @return uint256 : amount queued
   */
  function queuedForWithdrawal(address token) public view returns (uint256) {
    if (tokenIndexes[token].queueIndex <= tokenIndexes[token].redeemIndex) return 0;
    return tokenIndexes[token].queueIndex - tokenIndexes[token].redeemIndex;
  }

  /**
   * @notice Returns an user Redeem tickets
   * @param user Address of the user
   * @return RedeemTicket[] : user Redeem tickets
   */
  function getUserRedeemTickets(address user) external view returns (RedeemTicket[] memory) {
    return userRedeems[user];
  }

  /**
   * @notice Returns an user active Redeem tickets
   * @param user Address of the user
   * @return RedeemTicket[] : user active Redeem tickets
   */
  function getUserActiveRedeemTickets(address user) external view returns (RedeemTicket[] memory) {
    RedeemTicket[] memory _userTickets = userRedeems[user];
    uint256 length = _userTickets.length;
    uint256 activeTickets;

    // Get the amount of non-redeemed tickets
    for (uint256 i; i < length;) {
      if (!_userTickets[i].redeemed) {
        unchecked {
          ++activeTickets;
        }
      }
      unchecked {
        ++i;
      }
    }

    // Create the array of non-redeemed tickets & list them
    RedeemTicket[] memory activeRedeemTickets = new RedeemTicket[](activeTickets);
    uint256 j;
    for (uint256 i; i < length;) {
      if (!_userTickets[i].redeemed) {
        activeRedeemTickets[j] = _userTickets[i];
        unchecked {
          ++j;
        }
      }
      unchecked {
        ++i;
      }
    }

    return activeRedeemTickets;
  }

  /**
   * @notice Returns the current weights of all listed tokens for redeeming
   * @return TokenWeight[] : weights and address for each token
   */
  function getTokenWeights() external view returns (TokenWeight[] memory) {
    uint256 length = tokens.length;
    TokenWeight[] memory _tokens = new TokenWeight[](length);
    for (uint256 i; i < length; i++) {
      _tokens[i] = TokenWeight(tokens[i], _getTokenWeight(tokens[i]));
    }
    return _tokens;
  }

  // State Changing Functions

  /**
   * @notice Notifies when a Locker unlocks token and send them to this contract
   * @param token Address of the token
   * @param amount Amount of token unlocked
   */
  function notifyUnlock(address token, uint256 amount) external whenNotPaused {
    if (lockerTokens[msg.sender] == address(0)) revert Errors.NotListedLocker();

    // Update the redeem index for the token based on the amount unlocked & sent by the Locker
    tokenIndexes[token].redeemIndex += amount;
  }

  /**
   * @notice Joins the redeem queue for each token & burns the given amount of WAR token
   * @param amount Amount of WAR to burn
   */
  function joinQueue(uint256 amount) external nonReentrant whenNotPaused {
    address[] memory _tokens = tokens;
    uint256 tokensLength = _tokens.length;
    if (amount == 0) revert Errors.ZeroValue();

    // Pull the WAR token to burn
    IERC20(war).safeTransferFrom(msg.sender, address(this), amount);

    // Calculate the fee & burn amount
    uint256 feeAmount = (amount * redeemFee) / MAX_BPS;
    uint256 burnAmount = amount - feeAmount;

    // Transfer out the fees & burn the rest of the WAR tokens
    IERC20(war).safeTransfer(feeReceiver, feeAmount);

    for (uint256 i; i < tokensLength;) {
      if (lockers[_tokens[i]] == address(0)) revert Errors.NotListedLocker();

      uint256 weight = _getTokenWeight(_tokens[i]);

      // Calculate the amount of WAR burned for each token in the list
      // based on the given weights
      uint256 warAmount = (burnAmount * weight) / UNIT;
      // Get the amount of token to redeem based on the WAR amount
      uint256 redeemAmount = ratios.getBurnAmount(_tokens[i], warAmount);

      // Not need for a ticket if the weight gives a value of 0
      if (redeemAmount == 0) continue;

      // Join the redeem queue for the token
      _joinQueue(_tokens[i], msg.sender, redeemAmount);

      unchecked {
        ++i;
      }
    }

    // We burn the WAR at the end to avoid invalid
    // calculations during weight calculations
    WarToken(war).burn(address(this), burnAmount);
  }

  /**
   * @notice Redeems tickets to receive the tokens
   * @param tickets List of tickets to redeem
   * @param receiver Address to receive the tokens
   */
  function redeem(uint256[] calldata tickets, address receiver) external nonReentrant whenNotPaused {
    if (receiver == address(0)) revert Errors.ZeroAddress();

    uint256 ticketsLength = tickets.length;
    if (ticketsLength == 0) revert Errors.EmptyArray();

    for (uint256 i; i < ticketsLength;) {
      // Redeem for each ticket
      _redeem(msg.sender, receiver, tickets[i]);

      unchecked {
        ++i;
      }
    }
  }

  // Internal Functions

  /**
   * @dev Calculates the redeem ratio for the given token
   * @param token Address of the token
   * @return (uint256) : weight of the token
   */
  function _getTokenWeight(address token) internal view returns (uint256) {
    uint256 totalWarSupply = WarToken(war).totalSupply();
    if (totalWarSupply == 0) return 0;

    uint256 tokenBalance = IWarLocker(lockers[token]).getCurrentLockedTokens();
    uint256 queuedAmount = queuedForWithdrawal(token);
    tokenBalance = tokenBalance > queuedAmount ? tokenBalance - queuedAmount : 0;
    uint256 tokenRatio = ratios.getTokenRatio(token);

    return ((tokenBalance * tokenRatio)) / totalWarSupply;
  }

  /**
   * @dev Creates a new Redeem ticket for the given token, based on the calculated redeem amount
   * @param token Address of the token
   * @param user Address of the user owning the ticket
   * @param amount Amount to be redeemed
   */
  function _joinQueue(address token, address user, uint256 amount) internal {
    TokenIndex storage tokenIndex = tokenIndexes[token];

    // Update the queue index based on the amount to redeem
    uint256 newQueueIndex = tokenIndex.queueIndex + amount;
    tokenIndex.queueIndex = newQueueIndex;

    uint256 userNextTicketId = userRedeems[user].length;

    // Add a new ticket to the user list,
    // using the new queue index as the redeem index for this ticket
    userRedeems[user].push(
      RedeemTicket({id: userNextTicketId, token: token, amount: amount, redeemIndex: newQueueIndex, redeemed: false})
    );

    emit NewRedeemTicket(token, user, userNextTicketId, amount, newQueueIndex);
  }

  /**
   * @dev Executes the redeem for the given ticket & transfer out the tokens
   * @param user Address of the user
   * @param receiver Address to receive the tokens
   * @param ticketNumber Index of the ticket in the user's list
   */
  function _redeem(address user, address receiver, uint256 ticketNumber) internal {
    if (ticketNumber >= userRedeems[user].length) revert Errors.InvalidIndex();

    // Load the ticket & the token
    RedeemTicket storage redeemTicket = userRedeems[user][ticketNumber];
    address token = redeemTicket.token;

    // Process any potential unlock for the Locker to update the redeem index
    IWarLocker(lockers[token]).processUnlock();

    // Check if the token's redeem index is high enough for this redeem
    if (redeemTicket.redeemIndex > tokenIndexes[token].redeemIndex) revert Errors.CannotRedeemYet();

    if (redeemTicket.redeemed) revert Errors.AlreadyRedeemed();
    redeemTicket.redeemed = true;

    // Send the tokens to the receiver
    IERC20(token).safeTransfer(receiver, redeemTicket.amount);

    emit Redeemed(token, user, receiver, ticketNumber);
  }

  // Admin Functions

  /**
   * @notice Sets a Locker contract for a given token
   * @param token Address of the token
   * @param warLocker Address of the Locker contract
   */
  function setLocker(address token, address warLocker) external onlyOwner {
    if (token == address(0) || warLocker == address(0)) revert Errors.ZeroAddress();

    address expectedToken = IWarLocker(warLocker).token();
    if (expectedToken != token) revert Errors.MismatchingLocker(expectedToken, token);

    if (lockers[token] == address(0)) {
      // New token listed
      tokens.push(token);
    }

    lockers[token] = warLocker;
    lockerTokens[warLocker] = token;

    emit SetWarLocker(token, warLocker);
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

  /**
   * @notice Sets the Fee Receiver address
   * @param newFeeReceiver Address to receive the fees
   */
  function setFeeReceiver(address newFeeReceiver) external onlyOwner {
    if (newFeeReceiver == address(0)) revert Errors.ZeroAddress();

    address oldFeeReceiver = feeReceiver;
    feeReceiver = newFeeReceiver;

    emit FeeReceiverUpdated(oldFeeReceiver, newFeeReceiver);
  }

  /**
   * @notice Sets a new Redeem Fee
   * @param newRedeemFee Ratio (BPS) for the Redeem Fee
   */
  function setRedeemFee(uint256 newRedeemFee) external onlyOwner {
    if (newRedeemFee == 0 || newRedeemFee > 1000) revert Errors.InvalidParameter();

    uint256 oldRedeemFee = redeemFee;
    redeemFee = newRedeemFee;

    emit RedeemFeeUpdated(oldRedeemFee, newRedeemFee);
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

  /**
   * @notice Recover ERC2O tokens in the contract
   * @dev Recover ERC2O tokens in the contract
   * @param token Address of the ERC2O token
   * @return bool: success
   */
  function recoverERC20(address token) external onlyOwner returns (bool) {
    if (token == address(war) || lockers[token] != address(0)) revert Errors.RecoverForbidden();

    if (token == address(0)) revert Errors.ZeroAddress();
    uint256 amount = IERC20(token).balanceOf(address(this));
    if (amount == 0) revert Errors.ZeroValue();

    IERC20(token).safeTransfer(owner(), amount);

    return true;
  }
}
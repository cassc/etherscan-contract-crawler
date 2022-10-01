// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

        ████████████
      ██            ██
    ██              ██▓▓
    ██            ████▓▓▓▓▓▓
    ██      ██████▓▓▒▒▓▓▓▓▓▓▓▓
    ████████▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒
    ██    ████████▓▓▒▒▒▒▒▒▒▒▒▒
    ██            ██▓▓▒▒▒▒▒▒▒▒
    ██              ██▓▓▓▓▓▓▓▓
    ██    ██      ██    ██       '||''|.                    ||           '||
    ██                  ██        ||   ||  ... ..   ....   ...  .. ...    || ...    ...   ... ... ...
      ██              ██          ||'''|.   ||' '' '' .||   ||   ||  ||   ||'  || .|  '|.  ||  ||  |
        ██          ██            ||    ||  ||     .|' ||   ||   ||  ||   ||    | ||   ||   ||| |||
          ██████████             .||...|'  .||.    '|..'|' .||. .||. ||.  '|...'   '|..|'    |   |

*/

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title UpdatableSplitter
 * @dev This contract is similar to a common PaymentSplitter except it trades the ability
 * to pay each payee individually for the option to update its payees and their splits.
 */
contract UpdatableSplitter is Context, AccessControl {
  event PayeeAdded(address account, uint256 shares);
  event EtherFlushed(uint256 amount);
  event TokenFlushed(IERC20 indexed token, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  bytes32 public constant FLUSHWORTHY = keccak256("FLUSHWORTHY");

  uint256 private _totalShares;
  address[] private _payees;
  mapping(address => uint256) private _shares;

  address[] private _commonTokens;

  /**
   * @dev Takes a list of payees and a corresponding list of shares.
   *
   * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no duplicates in `payees`.
   *
   * Additionally takes a list of ERC20 token addresses that can be flushed with `flushCommon`.
   */
  constructor(
    address[] memory payees,
    uint256[] memory shares_,
    address[] memory tokenAddresses
  ) payable {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(FLUSHWORTHY, _msgSender());

    for (uint256 i = 0; i < payees.length; i++) {
      _grantRole(FLUSHWORTHY, payees[i]);
    }

    updateSplit(payees, shares_);

    _commonTokens = tokenAddresses;
  }

  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  /**
   * @dev Getter for the total shares held by payees.
   */
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the address of an individual payee.
   */
  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  /**
   * @dev Getter for the assigned number of shares for a given payee.
   */
  function shares(address payee_) public view returns (uint256) {
    return _shares[payee_];
  }

  /**
   * @dev Function to add ERC20 token addresses to the list of common tokens.
   */
  function addToken(address tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(tokenAddress != address(0), "UpdatableSplitter: address is the zero address");
    _commonTokens.push(tokenAddress);
  }

  /**
   * @dev Updates the list of payees and their corresponding shares. Requires both lists to be same length.
   *
   * Flushes all holdings before updating.
   */
  function updateSplit(address[] memory payees, uint256[] memory shares_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(payees.length == shares_.length, "UpdatableSplitter: payees and shares length mismatch");
    require(payees.length > 0, "UpdatableSplitter: no payees");

    flushCommon();
    _clear();

    for (uint256 i = 0; i < payees.length; i++) {
      _addPayee(payees[i], shares_[i]);
    }
  }

  /**
   * @dev Flushes all Ether held by contract, split according to the shares.
   */
  function flush() public onlyRole(FLUSHWORTHY) {
    (uint256 unit, uint256 balance) = _unitAndBalance();

    if (unit == 0 || balance == 0) return;

    for (uint256 i = 0; i < _payees.length; i++) {
      address payee_ = payee(i);
      uint256 split = shares(payee_) * unit;
      Address.sendValue(payable(payee_), split);
    }

    emit EtherFlushed(balance);
  }

  /**
   * @dev Flushes total balance of given ERC20 token, split according to the shares.
   */
  function flushToken(IERC20 token) public onlyRole(FLUSHWORTHY) {
    (uint256 unit, uint256 balance) = _unitAndBalance(token);

    if (unit == 0 || balance == 0) return;

    for (uint256 i = 0; i < _payees.length; i++) {
      address payee_ = payee(i);
      uint256 split = shares(payee_) * unit;
      SafeERC20.safeTransfer(token, payee_, split);
    }

    emit TokenFlushed(token, balance);
  }

  /**
   * @dev Flushes all Ether + all registered common tokens, split according to the shares.
   */
  function flushCommon() public onlyRole(FLUSHWORTHY) {
    flush();

    for (uint256 i = 0; i < _commonTokens.length; i++) {
      flushToken(IERC20(_commonTokens[i]));
    }
  }

  function _clear() private {
    for (uint256 i = 0; i < _payees.length; i++) {
      _shares[payee(i)] = 0;
    }
    delete _payees;

    _totalShares = 0;
  }

  function _addPayee(address account, uint256 shares_) private {
    require(account != address(0), "UpdatableSplitter: account is the zero address");
    require(shares_ > 0, "UpdatableSplitter: shares are 0");
    require(shares(account) == 0, "UpdatableSplitter: account already has shares");

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;

    emit PayeeAdded(account, shares_);
  }

  function _unitAndBalance() private view returns (uint256, uint256 balance) {
    balance = uint256(address(this).balance);
    if (_totalShares == 0 || balance == 0) return (0, 0);
    return (balance / _totalShares, balance);
  }

  function _unitAndBalance(IERC20 token) private view returns (uint256, uint256 balance) {
    balance = token.balanceOf(address(this));
    if (_totalShares == 0 || balance == 0) return (0, 0);
    return (balance / _totalShares, balance);
  }
}
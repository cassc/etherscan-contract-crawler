/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: PaymentSplitterV2.sol
 * @author: OG was OZ, rewritten by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Updated to add/subtract payees
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IMAXPaymentSplitter.sol";
import "../access/MaxAccess.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Removal of SafeMath due to ^0.8.0 standards, not needed

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */

abstract contract PaymentSplitterV2 is MaxAccess
                                     , IMAXPaymentSplitter {

  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);
  event PayeeRemoved(address account, uint256 shares);
  event PayeesReset();

  uint256 private _totalShares;
  uint256 private _totalReleased;
  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   *
   *  receive() external payable virtual {
   *    emit PaymentReceived(msg.sender, msg.value);
   *  }
   *
   *  // Fallback function is called when msg.data is not empty
   *  // Added to PaymentSplitter.sol
   *  fallback() external payable {
   *    emit PaymentReceived(msg.sender, msg.value);
   *  }
   *
   * receive() and fallback() to be handled at final contract
   */

  /**
   * @dev Getter for the total shares held by payees.
   */
  function totalShares() 
    external
    view
    virtual
    override
    returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased()
    external
    view
    virtual
    override
    returns (uint256) {
    return _totalReleased;
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _released[account];
  }

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function payee(
    uint256 index
  ) external
    view
    virtual
    override
    returns (address) {
    return _payees[index];
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  // This function was updated from "account" to msg.sender
  function claim()
    external
    virtual
    override {
    address check = msg.sender;

    if (_shares[check] == 0) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " has no shares."
                  )
                )
      });
    }

    uint256 totalReceived = address(this).balance + _totalReleased;
    uint256 payment = (totalReceived * _shares[check]) / _totalShares - _released[check];

    if (payment == 0) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " is not due payment."
                  )
                )
      });
    }

    _released[check] = _released[check] + payment;
    _totalReleased = _totalReleased + payment;

    Address.sendValue(payable(check), payment);
    emit PaymentReleased(check, payment);
  }

  // now the internal logic of this contract

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  // This function was updated to internal
  function _addPayee(
    address account
  , uint256 shares_
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "PaymentSplitter: account is the zero address"
      });
    } else if (shares_ == 0) {
      revert MaxSplaining({
        reason: "PaymentSplitter: shares are 0"
      });
    } else if (_shares[account] > 0) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(account), 20),
                    " already has ",
                    Strings.toString(_shares[account]),
                    " shares."
                  )
                )
      });
    }

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;

    emit PayeeAdded(account, shares_);
  }

  /**
   * @dev finds index in array
   * @param account The address of the payee
   */
  function _findIndex(
    address account
  ) internal
    view
    returns (uint index) {
    uint max = _payees.length;
    for (uint i = 0; i < max;) {
      if (_payees[i] == account) {
        index = i;
      }
      unchecked { ++i; }
    }
  }

  /**
   * @dev Remove a payee to the contract.
   * @param account The address of the payee to remove.
   * leaves all payment data in the contract incase something was claimed
   */
  function _removePayee(
    address account
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "PaymentSplitter: account is the zero address"
      });
    } 

    // This finds the payee in the array _payees and removes it
    uint remove = _findIndex(account);
    address last = _payees[_payees.length - 1];
    _payees[remove] = last;
    _payees.pop();

    uint removeTwo = _shares[account];
    _shares[account] = 0;
    _totalShares = _totalShares - removeTwo;

    emit PayeeRemoved(account, removeTwo);
  }

  /**
   * @dev clears all data in PaymentSplitterV2
   * leaves all payment data in the contract incase something was claimed
   */
  function _clearAll()
    internal {
    uint max = _payees.length;
    for (uint i = 0; i < max;) {
      address account = _payees[i];
      _shares[account] = 0;
      unchecked { ++i; }
    }
    delete _totalShares;
    delete _payees;
    emit PayeesReset();
  }

  // @notice: This adds a payment split to PaymentSplitterV2.sol
  // @param newSplit: Address of payee
  // @param newShares: Shares to send user
  function addSplit (
    address newSplit
  , uint256 newShares
  ) external
    virtual
    override
    onlyDev() {
    _addPayee(newSplit, newShares);
  }

  // @notice: This removes a payment split on PaymentSplitterV2.sol
  // @param remSplit: Address of payee to remove
  function removeSplit (
    address remSplit
  ) external
    virtual
    override
    onlyDev() {
    _removePayee(remSplit);
  }

  // @notice: This removes all payment splits on PaymentSplitterV2.sol
  function clearSplits()
    external
    virtual
    override
    onlyDev() {
    _clearAll();
  }
}
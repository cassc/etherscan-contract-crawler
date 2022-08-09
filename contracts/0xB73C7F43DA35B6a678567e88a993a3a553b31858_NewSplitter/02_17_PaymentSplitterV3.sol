/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: PaymentSplitterV3.sol
 * @author: rewritten by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: original source OZ(4.7)
 *          https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol
 *          rewritten to pay all/remove payees/add payees post deployment
 *          PaymentSplitterV2.sol + ERC20 support + Code Comments/ERC-165
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./IPaymentSplitterV3.sol";
import "../../access/MaxAccess.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */

abstract contract PaymentSplitterV3 is MaxAccess
                                     , IPaymentSplitterV3 {
  uint256 private _totalShares;
  uint256 private _totalReleased;
  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  mapping(IERC20 => uint256) private _erc20TotalReleased;
  mapping(IERC20 => mapping(address => uint256)) private _erc20Released;
  address[] private _payees;
  IERC20[] private _authTokens;

  event TokenAdded(IERC20 indexed token);
  event TokenRemoved(IERC20 indexed token);
  event TokensReset();
  event PayeeAdded(address account, uint256 shares);
  event PayeeRemoved(address account, uint256 shares);
  event PayeesReset();
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

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

  // Internals of this contract

  // @dev: returns uint of payment for account in wei
  // @param account: account to lookup
  // @return: uint of wei
  function _pendingPayment(
    address account
  ) internal
    view
    returns (uint256) {
    uint totalReceived = address(this).balance + _totalReleased;
    return (totalReceived * _shares[account]) / _totalShares - _released[account];
  }

  // @dev: returns uint of payment in ERC20.decimals()
  // @param token: IERC20 address of token
  // @param account: account to lookup
  // @return: uint of ERC20.decimals()
  function _pendingPayment(
    IERC20 token
  , address account
  ) internal
    view
    returns (uint256) {
    uint totalReceived = token.balanceOf(address(this)) + _erc20TotalReleased[token];
    return (totalReceived * _shares[account]) / _totalShares - _erc20Released[token][account];
  }

  // @dev: claims "eth" for user
  // @param user: address of user
  function _claimETH(
    address user
  ) internal {
    if (_shares[user] == 0) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(user), 20),
                    " has no shares."
                  )
                )
      });
    }

    uint256 payment = _pendingPayment(user);

    if (payment == 0) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(user), 20),
                    " is not due \"eth\" payment."
                  )
                )
      });
    }

    // _totalReleased is the sum of all values in _released.
    // If "_totalReleased += payment" does not overflow,
    // then "_released[account] += payment" cannot overflow.
    _totalReleased += payment;
    unchecked {
      _released[user] += payment;
    }
    Address.sendValue(payable(user), payment);
    emit PaymentReleased(user, payment);
  }

  // @dev: claims ERC20 for user
  // @param token: ERC20 Contract Address
  // @param user: address of user
  function _claimERC20(
    IERC20 token
  , address user
  ) internal {
    if (_shares[user] == 0) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(user), 20),
                    " has no shares."
                  )
                )
      });
    }

    uint256 payment = _pendingPayment(token, user);

    if (payment == 0) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(user), 20),
                    " is not due ERC20 payment."
                  )
                )
      });
    }

    // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
    // If "_erc20TotalReleased[token] += payment" does not overflow,
    // then "_erc20Released[token][account] += payment" cannot overflow.
    _erc20TotalReleased[token] += payment;
    unchecked {
      _erc20Released[token][user] += payment;
    }
    SafeERC20.safeTransfer(token, user, payment);
    emit ERC20PaymentReleased(token, user, payment);
  }

  // @dev: this claims both "eth" and ERC20 for user based off _authTokens[]
  // @param user: address of user
  function _claimAll(
    address user
  ) internal {
    _claimETH(user);
    uint len = _authTokens.length;
    for (uint x = 0; x < len;) {
      _claimERC20(_authTokens[x], user);
      unchecked {
        ++x;
      }
    }
  }

  // @dev: this claims both "eth" and ERC20 for user based off _authTokens[] and all _payees[]
  function _payAll()
    internal {
    uint len = _payees.length;
    for (uint x = 0; x < len;) {
      _claimAll(_payees[x]);
      unchecked {
        ++x;
      }
    }
  }

  // @dev: this will add a payee to PaymentSplitterV3
  // @param account: address of account to add
  // @param shares: uint256 of shares to add to account
  function _addPayee(
    address account
  , uint256 addShares
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "PaymentSplitter: account can not be address(0)"
      });
    } else if (addShares == 0) {
      revert MaxSplaining({
        reason: "PaymentSplitter: shares can not be 0"
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
    _shares[account] = addShares;
    _totalShares = _totalShares + addShares;

    emit PayeeAdded(account, addShares);
  }

  // @dev: finds index of an account in _payees
  // @param account: address of account to find
  // @return index: position of account in address[] _payees
  function _findIndex(
    address account
  ) internal
    view
    returns (uint index) {
    uint len = _payees.length;
    for (uint x = 0; x < len;) {
      if (_payees[x] == account) {
        index = x;
      }
      unchecked {
        ++x;
      }
    }
  }

  // @dev: removes an account in _payees
  // @param account: address of account to remove
  // @notice: will keep payment data in there
  function _removePayee(
    address account
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "PaymentSplitter: account can not be address(0)"
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

  // @dev: this clears all shares/users from PaymentSplitterV3
  //       this WILL leave the payments already claimed on contract
  function _clearPayees()
    internal {
    uint len = _payees.length;
    for (uint x = 0; x < len;) {
      address account = _payees[x];
      _shares[account] = 0;
      unchecked {
         ++x;
      }
    }
    delete _totalShares;
    delete _payees;
    emit PayeesReset();
  }

  // @dev: this returns if token is in _authTokens[]
  // @param token: IERC20 to check
  // @return check: bool true/false (default)
  function _tokenCheck(
    IERC20 token
  ) internal
    returns (bool check) {
    uint len = _authTokens.length;
    for (uint x = 0; x < len;) {
      if (_authTokens[x] == token) {
        check = true;
      }
      unchecked {
        ++x;
      }
    }
  }

  // @dev: this adds an ERC20 to _authTokens[]
  // @param token: IERC20 to add
  // @notice: will call _tokenCheck(token) for error/revert
  function _addToken(
    IERC20 token
  ) internal {
    if (address(token) == address(0)) {
      revert MaxSplaining({
        reason: "PaymentSplitter: ERC20 contract address can not be address(0)"
      });
    }
    if (_tokenCheck(token)) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(address(token)), 20),
                    " is already in _authTokens"
                  )
                )
      });
    }

    _authTokens.push(token);
    emit TokenAdded(token);
  }

  // @dev: finds token in _authTokens[]
  // @param token: ERC20 token to find
  // @return index: position of account in IERC20[] _authTokens
  function _findToken(
    IERC20 token
  ) internal
    view
    returns (uint index) {
    uint len = _authTokens.length;
    for (uint x = 0; x < len;) {
      if (_authTokens[x] == token) {
        index = x;
      }
      unchecked {
        ++x;
      }
    }
  }

  // @dev: removes token in _authTokens[]
  // @param token: ERC20 token to remove
  function _removeToken(
    IERC20 token
  ) internal {
    if (address(token) == address(0)) {
      revert MaxSplaining({
        reason: "PaymentSplitter: ERC20 contract address can not be address(0)"
      });
    }
    if (!_tokenCheck(token)) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "PaymentSplitter: ",
                    Strings.toHexString(uint160(address(token)), 20),
                    " is not in _authTokens"
                  )
                )
      });
    }

    // This finds the payee in the array _payees and removes it
    uint remove = _findToken(token);
    IERC20 last = _authTokens[_payees.length - 1];
    _authTokens[remove] = last;
    _payees.pop();

    emit TokenRemoved(token);
  }

  // @dev: this clears all tokens from _authTokens[]
  function _clearTokens()
    internal {
    delete _authTokens;
    emit TokensReset();
  }

  // Now the externals, listed by use

  // @dev: this claims all "eth" on contract for msg.sender
  function claim()
    external
    virtual
    override {
    _claimETH(msg.sender);
  }

  // @dev: this claims all ERC20 on contract for msg.sender
  // @param token: ERC20 Contract Address
  function claim(
    IERC20 token
  ) external
    virtual
    override {
    _claimERC20(token, msg.sender);
  }


  // @dev: this claims all "eth" and ERC20's from IERC20[] _authTokens
  //       on contract for msg.sender
  function claimAll()
    external
    virtual
    override {
    _claimAll(msg.sender);
  }

  // @dev: This adds a payment split to PaymentSplitterV3.sol
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

  // @dev: This pays all payment splits on PaymentSplitterV3.sol
  function paySplits()
    external
    virtual
    override
    onlyDev() {
    _payAll();
  }

  // @dev: This removes a payment split on PaymentSplitterV3.sol
  // @param remove: Address of payee to remove
  // @notice: use paySplits() prior to use if anything is on the contract
  function removeSplit (
    address remove
  ) external
    virtual
    override
    onlyDev() {
    _removePayee(remove);
  }

  // @dev: This removes all payment splits on PaymentSplitterV3.sol
  // @notice: use paySplits() prior to use if anything is on the contract
  function clearSplits()
    external
    virtual
    override
    onlyDev() {
    _clearPayees();
  }

  // @dev: This adds a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to add
  function addToken(
    IERC20 token
  ) external
    virtual
    override
    onlyDev() {
    _addToken(token);
  }

  // @dev: This removes a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to remove
  function removeToken(
    IERC20 token
  ) external
    virtual
    override
    onlyDev() {
    _removeToken(token);
  }

  // @dev: This removes all _authTokens on PaymentSplitterV3.sol
  function clearTokens()
    external
    virtual
    override
    onlyDev() {
    _clearTokens();
  }

  // @dev: returns total shares
  // @return: uint256 of all shares on contract
  function totalShares()
    external
    view
    virtual
    override
    returns (uint256) {
    return _totalShares;
  }

  // @dev: returns total releases in "eth"
  // @return: uint256 of all "eth" released in wei
  function totalReleased()
    external
    view
    virtual
    override
    returns (uint256) {
    return _totalReleased;
  }

  // @dev: returns total releases in ERC20
  // @param token: ERC20 Contract Address
  // @return: uint256 of all ERC20 released in IERC20.decimals()
  function totalReleased(
    IERC20 token
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _erc20TotalReleased[token];
  }

  // @dev: returns shares of an address
  // @param account: address of account to return
  // @return: mapping(address => uint) of _shares
  function shares(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _shares[account];
  }

  // @dev: returns released "eth" of an account
  // @param account: address of account to look up
  // @return: mapping(address => uint) of _released
  function released(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _released[account];
  }


  // @dev: returns released ERC20 of an account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: mapping(address => uint) of _released
  function released(
    IERC20 token
  , address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _erc20Released[token][account];
  }

  // @dev: returns index number of payee
  // @param index: number of index
  // @return: address at _payees[index]
  function payee(
    uint256 index
  ) external
    view
    virtual
    override
    returns (address) {
    return _payees[index];
  }

  // @dev: returns amount of "eth" that can be released to account
  // @param account: address of account to look up
  // @return: uint in wei of "eth" to release
  function releasable(
    address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _pendingPayment(account);
  }

  // @dev: returns amount of ERC20 that can be released to account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: uint in IERC20.decimals() of ERC20 to release
  function releasable(
    IERC20 token
  , address account
  ) external
    view
    virtual
    override
    returns (uint256) {
    return _pendingPayment(token, account);
  }

  // @dev: this returns the array of _authTokens[]
  // @return: IERC20[] _authTokens
  function supportedTokens()
    external
    view
    virtual
    override
    returns (IERC20[] memory) {
    return _authTokens;
  }

  // @dev: this returns the array length of _authTokens[]
  // @return: uint256 of _authTokens.length
  function supportedTokensLength()
    external
    view
    virtual
    override
    returns (uint256) {
    return _authTokens.length;
  }
}
/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Library 20
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Library for EIP 20
 * @custom:change-log Custom errors added above
 *
 * Include with 'using Lib20 for Lib20.Token;'
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

library Lib20 {

  struct Token {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    uint256 totalSupply;
    uint8 decimals;
    string name;
    string symbol;
  }

  error MaxSplaining(string reason);

  function setName(
    Token storage token
  , string memory newName
  ) internal {
    token.name = newName;
  }

  function getName(
    Token storage token
  ) internal
    view
    returns (string memory) {
    return token.name;
  }

  function setSymbol(
    Token storage token
  , string memory newSymbol
  ) internal {
    token.symbol = newSymbol;
  }

  function getSymbol(
    Token storage token
  ) internal
    view
    returns (string memory) {
    return token.symbol;
  }

  function setDecimals(
    Token storage token
  , uint8 newDecimals
  ) internal {
    token.decimals = newDecimals;
  }

  function getDecimals(
    Token storage token
  ) internal
    view
    returns (uint8) {
    return token.decimals;
  }

  function getTotalSupply(
    Token storage token
  ) internal
    view
    returns (uint256) {
    return token.totalSupply;
  }

  function getBalanceOf(
    Token storage token
  , address owner
  ) internal
    view
    returns (uint256) {
    return token.balances[owner];
  }

  function doTransfer(
    Token storage token
  , address from
  , address to
  , uint256 value
  ) internal
    returns (bool success) {
    uint256 fromBal = getBalanceOf(token, from);
    if (value > fromBal) {
      revert MaxSplaining({
        reason: "Max20:1"
      });
    }
    unchecked {
      token.balances[from] -= value;
      token.balances[to] += value;
    }
    return true;
  }

  function getAllowance(
    Token storage token
  , address owner
  , address spender
  ) internal 
    view
    returns (uint256) {
    return token.allowances[owner][spender];
  }

  function setApprove(
    Token storage token
  , address owner
  , address spender
  , uint256 amount
  ) internal 
    returns (bool) {
    token.allowances[owner][spender] = amount;
    return true;
  }

  function mint(
    Token storage token
  , address account
  , uint256 amount
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "Max20:2"
      });
    }
    token.totalSupply += amount;
    unchecked {
      token.balances[account] += amount;
    }
  }

  function burn(
    Token storage token
  , address account
  , uint256 amount
  ) internal {
    uint256 accountBal = getBalanceOf(token, account);
    if (amount > amount) {
      revert MaxSplaining({
        reason: "Max20:1"
      });
    }
    unchecked {
      token.balances[account] = accountBal - amount;
      token.totalSupply -= amount;
    }
  }
}
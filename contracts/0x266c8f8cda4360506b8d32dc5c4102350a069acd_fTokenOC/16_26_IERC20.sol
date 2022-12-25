/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title:  EIP-20: Token Standard 
 * @author: Fabian Vogelsteller, Vitalik Buterin
 * @dev The following standard allows for the implementation of a standard API for tokens within
 *      smart contracts. This standard provides basic functionality to transfer tokens, as well
 *      as allow tokens to be approved so they can be spent by another on-chain third party.
 * @custom:source https://eips.ethereum.org/EIPS/eip-20
 * @custom:change-log external -> external, string -> string memory (0.8.x)
 * @custom:change-log readability enhanced
 * @custom:change-log backwards compatability to EIP 165 added
 * @custom:change-log MIT -> Apache-2.0

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright and related rights waived via CC0.                               *
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

import "../165/IERC165.sol";

interface IERC20 is IERC165 {

  /// @dev Transfer Event
  /// @notice MUST trigger when tokens are transferred, including zero value transfers.
  /// @notice A token contract which creates new tokens SHOULD trigger a Transfer event
  ///         with the _from address set to 0x0 when tokens are created.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /// @dev Approval Event
  /// @notice MUST trigger on any successful call to approve(address _spender, uint256 _value).
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the name of the token - e.g. "MyToken".
  function name()
    external
    view
    returns (string memory);

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the symbol of the token. E.g. “HIX”.
  function symbol()
    external
    view
    returns (string memory);

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return uint8 returns the number of decimals the token uses - e.g. 8, means to divide the
  ///         token amount by 100000000 to get its user representation.
  function decimals()
    external
    view
    returns (uint8);

  /// @dev totalSupply
  /// @return uint256 returns the total token supply.
  function totalSupply()
    external
    view
    returns (uint256);

  /// @dev balanceOf
  /// @return balance returns the account balance of another account with address _owner.
  function balanceOf(
    address _owner
  ) external
    view
    returns (uint256 balance);

  /// @dev transfer
  /// @return success
  /// @notice Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to spend.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transfer(
    address _to
  , uint256 _value
  ) external
    returns (bool success);

  /// @dev transferFrom
  /// @return success
  /// @notice The transferFrom method is used for a withdraw workflow, allowing contracts to transfer
  ///         tokens on your behalf. This can be used for example to allow a contract to transfer
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transferFrom(
    address _from
  , address _to
  , uint256 _value
  ) external
    returns (bool success);

  /// @dev approve
  /// @return success
  /// @notice Allows _spender to withdraw from your account multiple times, up to the _value amount.
  ///         If this function is called again it overwrites the current allowance with _value.
  /// @notice To prevent attack vectors like the one described here and discussed here, clients
  ///         SHOULD make sure to create user interfaces in such a way that they set the allowance
  ///         first to 0 before setting it to another value for the same spender. THOUGH The contract
  ///         itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed
  ///         before
  function approve(
    address _spender
  , uint256 _value
  ) external
    returns (bool success);

  /// @dev allowance
  /// @return remaining uint256 of allowance remaining
  /// @notice Returns the amount which _spender is still allowed to withdraw from _owner.
  function allowance(
    address _owner
  , address _spender
  ) external
    view
    returns (uint256 remaining);

}
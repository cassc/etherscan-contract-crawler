/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IPaymentSplitterV3.sol
 * @author: OG was OZ, rewritten by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Interface extension for PaymentSplitter.sol
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

import "./IPaymentSplitterV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPaymentSplitterV3 is IPaymentSplitterV2 {

  // @dev: this claims all ERC20 on contract for msg.sender
  // @param token: ERC20 Contract Address
  function claim(
    IERC20 token
  ) external;

  // @dev: this claims all "eth" and ERC20's from IERC20[] _authTokens
  //       on contract for msg.sender
  function claimAll()
    external;

  // @dev: This adds a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to add
  function addToken(
    IERC20 token
  ) external;

  // @dev: This removes a token on PaymentSplitterV3.sol
  // @param token: ERC20 Contract Address to remove
  function removeToken(
    IERC20 token
  ) external;

  // @dev: This removes all _authTokens on PaymentSplitterV3.sol
  function clearTokens()
    external;

  // @dev: returns total releases in ERC20
  // @param token: ERC20 Contract Address
  // @return: uint256 of all ERC20 released in IERC20.decimals()
  function totalReleased(
    IERC20 token
  ) external
    view
    returns (uint256);

  // @dev: returns released ERC20 of an account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: mapping(address => uint) of _released
  function released(
    IERC20 token
  , address account
  ) external
    view
    returns (uint256);

  // @dev: returns amount of ERC20 that can be released to account
  // @param token: ERC20 Contract Address
  // @param account: address of account to look up
  // @return: uint in IERC20.decimals() of ERC20 to release
  function releasable(
    IERC20 token
  , address account
  ) external
    view
    returns (uint256);

  // @dev: this returns the array of _authTokens[]
  // @return: IERC20[] _authTokens
  function supportedTokens()
    external
    view
    returns (IERC20[] memory);

  // @dev: this returns the array length of _authTokens[]
  // @return: uint256 of _authTokens.length
  function supportedTokensLength()
    external
    view
    returns (uint256);
}
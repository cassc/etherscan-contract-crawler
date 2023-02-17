/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP] Safe ERC 20 Library
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Library makes use of bool success on transfer, transferFrom and approve of EIP 20
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

pragma solidity >= 0.8.0 < 0.9.0;

import "../eip/20/IERC20.sol";

library Safe20 {

  error MaxSplaining(string reason);

  function safeTransfer(
    IERC20 token
  , address to
  , uint256 amount
  ) internal {
    if (!token.transfer(to, amount)) {
      revert MaxSplaining({
        reason: "Safe20: token.transfer failed"
      });
    }
  }

  function safeTransferFrom(
    IERC20 token
  , address from
  , address to
  , uint256 amount
  ) internal {
    if (!token.transferFrom(from, to, amount)) {
      revert MaxSplaining({
        reason: "Safe20: token.transferFrom failed"
      });
    }
  }

  function safeApprove(
    IERC20 token
  , address spender
  , uint256 amount
  ) internal {
    if (!token.approve(spender, amount)) {
      revert MaxSplaining({
        reason: "Safe20: token.approve failed"
      });
    }
  }
}
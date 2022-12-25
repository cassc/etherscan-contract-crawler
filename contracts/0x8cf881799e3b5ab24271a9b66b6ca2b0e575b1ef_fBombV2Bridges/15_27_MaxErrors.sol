/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP]: MaxErrors, so I can import errors, anywhere minus libraries
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Does not have an ERC165 return since no external/public functions
 * @custom:change-log abstract contract -> interface
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

interface MaxErrors {

  /// @dev this is Unauthorized(), basically a catch all, zero description
  /// @notice 0x82b42900 bytes4 of this
  error Unauthorized();

  /// @dev this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  /// @param reason: Use the "Contract name: error"
  /// @notice 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

  /// @dev this is TooSoonJunior(), using times
  /// @param yourTime: should almost always be block.timestamp
  /// @param hitTime: the time you should have started
  /// @notice 0xf3f82ac5 bytes4 of this
  error TooSoonJunior(
    uint yourTime
  , uint hitTime
  );

  /// @dev this is TooLateBoomer(), using times
  /// @param yourTime: should almost always be block.timestamp
  /// @param hitTime: the time you should have ended
  /// @notice 0x43c540ef bytes4 of this
  error TooLateBoomer(
    uint yourTime
  , uint hitTime
  );

}
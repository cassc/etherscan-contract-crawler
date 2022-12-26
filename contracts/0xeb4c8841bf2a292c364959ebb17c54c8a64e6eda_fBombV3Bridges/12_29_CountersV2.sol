/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: CountersV2.sol
 * @author Matt Condon (@shrugs)
 * @notice Provides counters that can only be incremented, decremented, reset or set. 
 * This can be used e.g. to track the number of elements in a mapping, issuing ERC721 ids
 * or counting request ids.
 * @custom:change-log MIT -> Apache-2.0
 * @custom:change-log Edited for more NFT functionality added .set(uint)
 * @custom:change-log added event CounterNumberChangedTo(uint _number).
 * @custom:change-log added error MaxSplaining(string reason).
 * @custom:change-log internal -> internal functions
 * @custom:error-code CountersV2:1 "No negatives in uints" - overflow protection
 *
 * Include with `using CountersV2 for CountersV2.Counter;`
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

library CountersV2 {

  struct Counter {
    uint256 value;
  }

  event CounterNumberChangedTo(uint _number);

  error MaxSplaining(string reason);

  function current(
    Counter storage counter
  ) internal
    view
    returns (uint256) {
    return counter.value;
  }

  function increment(
    Counter storage counter
  ) internal {
    unchecked {
      ++counter.value;
    }
  }

  function decrement(
    Counter storage counter
  ) internal {
    if (counter.value == 0) {
      revert MaxSplaining({
        reason : "CountersV2:1"
      });
    }
    unchecked {
      --counter.value;
    }
  }

  function reset(
    Counter storage counter
  ) internal {
    counter.value = 0;
    emit CounterNumberChangedTo(counter.value);
  }

  function set(
    Counter storage counter
  , uint number
  ) internal {
    counter.value = number;
    emit CounterNumberChangedTo(counter.value);
  }  
}
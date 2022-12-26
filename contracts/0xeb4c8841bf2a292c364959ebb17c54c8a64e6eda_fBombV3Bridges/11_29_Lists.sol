/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP]: Access lists
 * @author: @MaxFlowO2 on bird app/GitHub
 * @dev Formerly whitelists, now allowlist, or whatever it's called.
 * @custom:change-log removed end variable/functions (un-needed)
 * @custom:change-log variables renamed from lib whitelist
 * @custom:change-log internal -> internal
 * @custom:error-code Lists:1 "(user) is already whitelisted."
 * @custom:error-code Lists:2 "(user) is not whitelisted."
 * @custom:error-code Lists:3 "Whitelist already enabled."
 * @custom:error-code Lists:4 "Whitelist already disabled."
 * @custom:change-log added custom error codes
 * @custom:change-log removed import "./Strings.sol"; (un-needed)
 *
 * Include with 'using Lists for Lists.Access;'
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

import "./CountersV2.sol";

library Lists {

  using CountersV2 for CountersV2.Counter;

  event ListChanged(bool _old, bool _new, address _address);
  event ListStatus(bool _old, bool _new);

  error MaxSplaining(string reason);

  struct Access {
    bool _status;
    CountersV2.Counter added;
    CountersV2.Counter removed;
    mapping(address => bool) allowed;
  }

  function add(
    Access storage list
  , address user
  ) internal {
    if (list.allowed[user]) {
      revert  MaxSplaining({
        reason : "Lists:1"
      });
    }
    // since now all previous values are false no need for another variable
    // and add them to the list!
    list.allowed[user] = true;
    // increment counter
    list.added.increment();
    // emit event
    emit ListChanged(false, list.allowed[user], user);
  }

  function remove(
    Access storage list
  , address user
  ) internal {
    if (!list.allowed[user]) {
      revert  MaxSplaining({
        reason : "Lists:2"
      });
    }
    // since now all previous values are true no need for another variable
    // and remove them from the list!
    list.allowed[user] = false;
    // increment counter
    list.removed.increment();
    // emit event
    emit ListChanged(true, list.allowed[user], user);
  }

  function enable(
    Access storage list
  ) internal {
    if (list._status) {
      revert  MaxSplaining({
        reason : "Lists:3"
      });
    }
    list._status = true;
    emit ListStatus(false, list._status);
  }

  function disable(
    Access storage list
  ) internal {
    if (!list._status) {
      revert  MaxSplaining({
        reason : "Lists:4"
      });
    }
    list._status = false;
    emit ListStatus(true, list._status);
  }

  function status(
    Access storage list
  ) internal
    view
    returns (bool) {
    return list._status;
  }

  function totalAdded(
    Access storage list
  ) internal
    view
    returns (uint) {
    return list.added.current();
  }

  function totalRemoved(
    Access storage list
  ) internal
    view
    returns (uint) {
    return list.removed.current();
  }

  function onList(
    Access storage list
  , address user
  ) internal
    view
    returns (bool) {
    return list.allowed[user];
  }
}
/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Splitter.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: This is to replace the contract abstract splitter for TinyDaemons
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

pragma solidity 0.8.15;

import "./modules/splitter/PaymentSplitterV3.sol";

contract NewSplitter is PaymentSplitterV3 {

  // @notice: Function to receive ether, msg.data must be empty
  receive() 
    external
    payable {
    // From PaymentSplitterV3.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  // @notice: Function to receive ether, msg.data is not empty
  fallback()
    external
    payable {
    // From PaymentSplitterV3.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  // @notice this is a public getter for ETH blance on contract
  function getBalance()
    external
    view
    returns (uint) {
    return address(this).balance;
  }

  // @notice: Standard override for ERC165
  // @param interfaceId: interfaceId to check for compliance
  // @return: bool if interfaceId is supported
  function supportsInterface(
    bytes4 interfaceId
  ) public
    view
    virtual
    override 
    returns (bool) {
    return (
      interfaceId == type(IRole).interfaceId  ||
      interfaceId == type(IDeveloper).interfaceId  ||
      interfaceId == type(IDeveloperV2).interfaceId  ||
      interfaceId == type(IOwner).interfaceId  ||
      interfaceId == type(IOwnerV2).interfaceId  ||
      interfaceId == type(IPaymentSplitterV2).interfaceId  ||
      interfaceId == type(IPaymentSplitterV3).interfaceId
    );
  }
}
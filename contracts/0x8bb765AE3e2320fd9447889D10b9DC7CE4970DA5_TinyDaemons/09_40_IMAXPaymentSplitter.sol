/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IMAXPaymentSplitter.sol
 * @author: OG was OZ, rewritten by Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Interface extension for PaymentSplitter.sol
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IPaymentSplitter.sol";

///
/// @dev Interface extension for PaymentSplitter
///

interface IMAXPaymentSplitter is IPaymentSplitter {

  // @notice: This adds a payment split to PaymentSplitterV2.sol
  // @param newSplit: Address of payee
  // @param newShares: Shares to send user
  function addSplit (
    address newSplit
  , uint256 newShares
  ) external;

  // @notice: This removes a payment split on PaymentSplitterV2.sol
  // @param remSplit: Address of payee to remove
  function removeSplit (
    address remSplit
  ) external;

  // @notice: This removes all payment splits on PaymentSplitterV2.sol
  function clearSplits()
    external;

}
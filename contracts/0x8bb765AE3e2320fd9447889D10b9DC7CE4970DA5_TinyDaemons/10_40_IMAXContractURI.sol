/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IMAXContractURI.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Extension for IContractURI
 */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IContractURI.sol";

interface IMAXContractURI is IContractURI {

  // @notice this sets the contractURI, set to internal
  // @param URI - string to URI of Contract Metadata
  // @notice: let the metadata be in this format
  // {
  //   "name": Project's name,
  //   "description": Project's Description,
  //   "image": pfp for project,
  //   "external_link": web url,
  //   "seller_fee_basis_points": 100 -> Indicates a 1% seller fee.
  //   "fee_recipient": checksum address
  // }
  function setContractURI(
    string memory URI
  ) external;
}
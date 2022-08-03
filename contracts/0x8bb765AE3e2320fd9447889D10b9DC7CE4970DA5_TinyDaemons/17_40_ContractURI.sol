/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: ContractURI.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Purely for OpenSea compliance
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IMAXContractURI.sol";
import "../access/MaxAccess.sol";

///
/// @dev Implementation of IMAXContractURI.sol
///

abstract contract ContractURI is MaxAccess
                               , IMAXContractURI {

  event ContractURIChange(
          string _old
        , string _new);

  string private thisContractURI;

  // @notice this sets the contractURI, set to internal
  // @param newURI - string to URI of Contract Metadata
  // @notice: let the metadata be in this format
  //{
  //  "name": Project's name,
  //  "description": Project's Description,
  //  "image": pfp for project,
  //  "external_link": web url,
  //  "seller_fee_basis_points": 100 -> Indicates a 1% seller fee.
  //  "fee_recipient": checksum address
  //}
  function _setContractURI(
    string memory newURI
  ) internal {
    string memory old = thisContractURI;
    thisContractURI = newURI;
    emit ContractURIChange(old, thisContractURI);
  }

  // @notice this clears the contractURI, set to internal
  function _clearContractURI() internal {
    string memory old = thisContractURI;
    delete thisContractURI;
    emit ContractURIChange(old, thisContractURI);
  }

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
  ) external
    virtual
    override
    onlyDev() {
    _setContractURI(URI);
  }

  // @notice contractURI() called for retreval of
  //  OpenSea style collections pages
  // @return - string thisContractURI
  function contractURI() 
    external
    view
    virtual
    override(IContractURI)
    returns (string memory) {
    return thisContractURI;
  }
}
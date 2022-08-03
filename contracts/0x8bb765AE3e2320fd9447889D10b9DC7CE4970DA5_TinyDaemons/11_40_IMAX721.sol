/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: IMAX721.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Interface for UX/UI
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for @MaxFlowO2's Contracts
///

interface IMAX721 is IERC165 {

  // @dev will return status of Minter
  // @return - bool of active or not
  function minterStatus() 
    external
    view
    returns (bool);

  // @dev will return minting fees
  // @return - uint of mint costs in wei
  function minterFees()
    external
    view
    returns (uint);

  // @dev will return maximum mint capacity
  // @return - uint of maximum mints allowed
  function minterMaximumCapacity()
    external
    view
    returns (uint);

  // @dev will return maximum "team minting" capacity
  // @return - uint of maximum airdrops or team mints allowed
  function minterMaximumTeamMints()
    external
    view
    returns (uint);

  // @dev will return "team mints" left
  // @return - uint of remaing airdrops or team mints
  function minterTeamMintsRemaining()
    external
    view
    returns (uint);

  // @dev will return "team mints" count
  // @return - uint of airdrops or team mints done
  function minterTeamMintsCount()
    external
    view
    returns (uint);

  // @dev: will return total supply for mint
  // @return: uint for this mint
  function totalSupply()
    external
    view
    returns (uint256);
}
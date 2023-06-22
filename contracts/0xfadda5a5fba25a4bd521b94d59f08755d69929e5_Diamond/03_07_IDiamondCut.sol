// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************\
 .    . . . . . . .... .. ...................... . . . .  .   .+
   ..  .   . .. . ............................ ... ....  . .. .+
 .   .  .. .. ....... ..;@@@@@@@@@@@@@@@@@@@;........ ... .  . +
  .   .  .. ...........X [email protected]@ 8  ....... .. .. .+
.  .. . . ... ... .:..% 8 [email protected] [email protected]%..8  .:...... . .  +
 .  . ... . ........:t:[email protected]@[email protected] ;  @......... .. ..+
.  . . . ........::.% 8 [email protected]  .   88:;:.:....... .+
.   . .. . .....:.:; [email protected]@88      S.88:.:........ .+
 . . .. .......:.:;88 @[email protected]@[email protected]@88888.   .888 88;.:..:..... +
.  .. .......:..:; [email protected] :  :Xt8 8 :S:.:........+
 .  .......:..:.;:8 8888888%8888888888 :. .888 8 88:;::::..... +
 . .. .......:::[email protected]@88%88888X ;. [email protected] 8  %:  8:..:.....+
. .........:..::[email protected] ;. :88SS 8t8.    @::......+
 . . .....:.::[email protected] 88 @88 @8 [email protected] 88 @::  8.8 8 [email protected]     88:.:.....v
. . .......:.:;t8 :8 8 88.8 8:8.:8 t8..88 8 8 @ 8   88;::.:....+
.. .......:.:::;.%8 @ 8 @ .8:@.8 ;8;8t8:[email protected] 8:8X    88t::::.....+
. .. ......:..:::t88 8 8 8 t8 %88 [email protected] @ 888 X 8 XX;::::.::...+
..........:::::::;:X:8 :8 8 ;8.8.8 @ :88 8:@ @   8X;::::::.:...+
  . .......:.:::::; 8 8.:8 8 t8:8 8 8.;88 XX  8 88t;:::::......+
.. .......:.:.:::::; @:8.;8 8.t8 8 tt8.%[email protected] 8  88t;:;::::.:....+
 ... ....:.:.:.::;::; 8:8 ;8 8 t8 8:8 8.t8S. 888;;:;::::.:..:..+
.  ........::::::::;:;.t 8 ;8 8 ;88:;8.8 ;88 88S:::::::.:.:....+
 .. .. .....:.:.:::::;; 888X8S8 [email protected] 888X:t;;;::::::.:.....+
 .. ........:..:::::;::;%;:   .t. ;ttS:;t. .  :;;:;:::.::......+
 . . ......:.:..::::::;;;t;;:;;;;;;;;t;;;;;:: :;:;:::.:........+
/***************************************************************/

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;    
}
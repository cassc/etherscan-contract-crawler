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

interface IDiamond {
  enum FacetCutAction {Add, Replace, Remove}
  // Add=0, Replace=1, Remove=2

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}
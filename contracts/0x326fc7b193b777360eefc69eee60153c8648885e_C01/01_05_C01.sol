// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Journey in Web3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                    ;8X:      //
//                                                                                                                                                  [email protected]     //
//                                                                                                                                                 [email protected]:.     //
//                                                                                                                                              :[email protected]:...      //
//                                                                                                                                           [email protected]@t:.;@t       //
//                                                                                                                                          @8X88::..t%.8;..    //
//                                                                                                                                       :St;88t%8;;X%888;.     //
//                                                                                                                                    [email protected];8S;:;:..      //
//                                                                                                                                   @88.X%8S%t;:...... .       //
//                                                                                                                               [email protected]%XXt;::.                //
//                                                                                                                          ;@St%S8 [email protected];;:..:..                  //
//                                                                                                                       %[email protected]:...                       //
//                                                                                                                 .%8;;StXXXS:.8S%:..                          //
//                                                                                                           :S;ttXSS;@;;:.::. [email protected]%                             //
//      ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... .X; 88t;:..:......:88X  . ... ...... .... ... ..    //
//                                                                                                          [email protected];;..   ..  ...X;8                               //
//                                                                                                         :;8%:...          S;8                                //
//                                                                                                         ;SX;..           Xt8;                                //
//                                                                                                        [email protected]:..           ;888.                                //
//                                                                                                      [email protected]@:.            :[email protected]                                 //
//                                                                                                      8%@:.             SXX:                                  //
//                                                                                                     [email protected] .             8SX:                                   //
//                                                                                                    [email protected]               XS8%.                                   //
//                                                                                                   [email protected]               :[email protected]@                                     //
//                                                                                                  %8X;              .X:X                                      //
//                                                                                                 X8X;               [email protected]                                       //
//                                                                   tt8.                :88:     ;[email protected]%               [email protected]                                       //
//                                                                   ; ;S.              tX:;@X.  ;%@S.              ;[email protected]                                       //
//                                                                  [email protected];8.        ;[email protected]@8%:.             :8:@.                                        //
//                                                                .;[email protected]::.:8%8%8.  :8%@88%tt:;[email protected]:.             :@:8.                                         //
//                                                                tS8t:  ...tttSS88;8S:;..   .;88X:[email protected]             S 8t                                          //
//                                                               [email protected]@:.    . [email protected];@8;@:...     :t8S;8XXX8:.        @[email protected]                                           //
//                                                             :;8S:.      :@%[email protected]%8..    ;XX%;:.:%@[email protected]:     [email protected]                                           //
//                                                             ;SXt.      88;8X:.::ttt%S.  .;@S..    .;X8%[email protected]   :[email protected]@.                                            //
//                                                           .%88t..  ;[email protected]  .  ..%[email protected];[email protected]:.        :@[email protected];@:X                                              //
//                                               S8%;%%S888S8 . XSSXX8X.88S:.       ...:8t:.8:.         . :[email protected]:                                             //
//                                              :8SX88t8:;88;[email protected]@[email protected];.            .:t8S%.              .:888                                               //
//                                             :[email protected]@[email protected];...:;.;:.               ..;.                 .;;                                                //
//                                            [email protected];.:.:.:%[email protected];..                                                                                                //
//                                           [email protected]      .;X%:                                                                                                   //
//                                         :%[email protected]%.      .;@@;.                                                                                                   //
//                                        @[email protected]@.       ;%@X:.                                                                                                    //
//                                       tt8S.       .t8S .                                                                                                     //
//                                     [email protected]:       :;8X.                                                                                                       //
//                                   [email protected]:..      tSXS.                                                                                                        //
//                                  .S;8;:..      .%8t:                                                                                                         //
//                                 %888t.   .:[email protected];8S8:                                                                                                          //
//                           S8%t%[email protected]%:ttSS%tS;%;@@..                                                                                                          //
//                          %S [email protected]%8St8S;t;;::. .:.                                                                                                            //
//                       .8;88X;@88%...:::....    .                                                                                                             //
//                    :8;8%[email protected]:8;;:. . ..                                                                                                                      //
//                  [email protected]:[email protected]@8%:.                                                                                                                             //
//               .X;[email protected]%@%.                                                                                                                               //
//            .8;8t 88888X%::  ..                                                                                                                               //
//           8S8;[email protected]::...                                                                                                                                    //
//      [email protected] [email protected]@t..  .                                                                                                                                       //
//      8%[email protected]%;::..                                                                                                                                            //
//     :;tS; . ..... ......... .............................................................................................................................    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract C01 is ERC1155Creator {
    constructor() ERC1155Creator("A Journey in Web3", "C01") {}
}
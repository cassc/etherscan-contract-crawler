// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SeattleDog
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    .           ..         .           .       .           .           .               //
//          .         .            .          .       .                                  //
//                .         ..xxxxxxxxxx....               .       .             .       //
//        .             MWMWWWSEATTLE DOGMWMWMWMW                       .                //
//                  IIIIMWMSEATTLE DOGMWMWMMWMWMWMWMttii:        .           .           //
//     .      IIYVVXMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWxx...         .           .    //
//         IWMWMWMWMWMWMWMWMWMWMWMWMWMWMSEATTLE DOGWMWMWMWMWMWMWMx..                     //
//       IIWMWMWMWMWMWMWMWMSEATTLE DOGMWMWMMWMWMWMWMWMWMWMWMWMWMWMWMx..        .         //
//        ""MWMWMWMWMWM"""""""".  .:..   ."""""MWMWMWMWMWMWMWMWMWMWMWMWMWti.             //
//     .     ""   . `  .: . :. : .  . :.  .  . . .  """"MWMWMWMWMWMWMWMWMWMWMWMWMti=     //
//            . .   :` . :   .  .'.' '....xxxxx...,'. '   ' ."""YWMWMWMWMWMWMWMWMWMW+    //
//         ; . ` .  . : . .' :  . ..XXXXXXXXXXXXXXXXXXXXx.    `     . "YWMWMWMWMWMWMW    //
//    .    .  .  .    . .   .  ..XXXXXXXXWWWWWWWWWWWWWWWWXXXX.  .     .     """""""      //
//            ' :  : . : .  ...XXXXXWWW"   [email protected]   .   .       . .       //
//       . ' .    . :   ...XXXXXXWWW"    M88N88GGGGGG888^8M "WMBX.          .   ..  :    //
//             :     ..XXXXXXXXWWW"     M88888WWRWWWMW8oo88M   WWMX.     .    :    .     //
//               "XXXXXXXXXXXXWW"       WN8888WWWWW  [email protected]@@8M    BMBRX.         .  : :    //
//      .       XXXXXXXX=MMWW":  .      W8N888WWWWWWWW88888W      XRBRXX.  .       .     //
//         ....  ""XXXXXMM::::. .        [email protected]@8N8W      . . :RRXx.    .         //
//             ``...'''  MMM::.:.  .      [email protected]      . . ::::"RXV    .  :     //
//     .       ..'''''      MMMm::.  .      WW888N88888WW     .  . mmMMMMMRXx            //
//          ..' .            ""MMmm .  .       WWWWWWW   . :. :,miMM"""  : ""`    .      //
//       .                .       ""MMMMmm . .  .  .   ._,mMMMM"""  :  ' .  :            //
//                   .                  ""MMMMMMMMMMMMM""" .  : . '   .        .         //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract SDOG is ERC1155Creator {
    constructor() ERC1155Creator("SeattleDog", "SDOG") {}
}
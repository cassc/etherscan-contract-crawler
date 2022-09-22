// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MindWandersWorlds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//        .                                               //
//                         M                              //
//                        dM                              //
//                        MMr                             //
//                       4MMML                  .         //
//                       MMMMM.                xf         //
//       .              "MMMMM               .MM-         //
//        Mh..          +MMMMMM            .MMMM          //
//        .MMM.         .MMMMML.          MMMMMh          //
//         )MMMh.        MMMMMM         MMMMMMM           //
//          3MMMMx.     'MMMMMMf      xnMMMMMM"           //
//          '*MMMMM      MMMMMM.     nMMMMMMP"            //
//            *MMMMMx    "MMMMM\    .MMMMMMM=             //
//             *MMMMMh   "MMMMM"   JMMMMMMP               //
//               MMMMMM   3MMMM.  dMMMMMM            .    //
//                MMMMMM  "MMMM  .MMMMM(        .nnMP"    //
//    =..          *MMMMx  MMM"  dMMMM"    .nnMMMMM*      //
//      "MMn...     'MMMMr 'MM   MMM"   .nMMMMMMM*"       //
//       "4MMMMnn..   *MMM  MM  MMP"  .dMMMMMMM""         //
//         ^MMMMMMMMx.  *ML "M .M*  .MMMMMM**"            //
//            *PMMMMMMhn. *x > M  .MMMM**""               //
//               ""**MMMMhx/.h/ .=*"                      //
//                        .3P"%....                       //
//                      nP"     "*MMnx                    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract MWW is ERC721Creator {
    constructor() ERC721Creator("MindWandersWorlds", "MWW") {}
}
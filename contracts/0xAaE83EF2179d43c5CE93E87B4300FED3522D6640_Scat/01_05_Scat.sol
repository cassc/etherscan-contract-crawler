// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scattering Stress
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//             ,,/’’’’’’\_,,                        //
//           ‘              ]                       //
//          , (o)           }                       //
//       < \               }             /’’’’’\    //
//          { ,,,,,,,,,,,,},,,,,,,,,,,,,/      /    //
//           (               {  ?  )     _____/     //
//          (    “            {  ? )    }           //
//           (      “          { ?)    }            //
//            (                       }             //
//              ********** *********                //
//                        C                         //
//                     / /  \\                      //
//                    / /    \\                     //
//                 F_/ /      \\_S                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Scat is ERC721Creator {
    constructor() ERC721Creator("Scattering Stress", "Scat") {}
}
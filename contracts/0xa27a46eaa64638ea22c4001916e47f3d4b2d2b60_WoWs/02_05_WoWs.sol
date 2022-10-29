// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World of Wheels
/// @author: manifold.xyz

import "./ERC721Creator.sol";

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


contract WoWs is ERC721Creator {
    constructor() ERC721Creator("World of Wheels", "WoWs") {}
}
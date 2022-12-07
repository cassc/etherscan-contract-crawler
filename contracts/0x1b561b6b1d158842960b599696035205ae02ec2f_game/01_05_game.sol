// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Game Day
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


contract game is ERC721Creator {
    constructor() ERC721Creator("Game Day", "game") {}
}
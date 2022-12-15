// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dewy Dynamic
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


contract Dew is ERC721Creator {
    constructor() ERC721Creator("Dewy Dynamic", "Dew") {}
}
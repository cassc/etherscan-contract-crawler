// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Something for Everyone
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


contract SoE is ERC721Creator {
    constructor() ERC721Creator("Something for Everyone", "SoE") {}
}
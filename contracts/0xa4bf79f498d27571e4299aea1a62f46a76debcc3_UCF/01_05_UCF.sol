// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ultimate Cock Fights by TTFF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    ██╗   ██╗ ██████╗███████╗    //
//    ██║   ██║██╔════╝██╔════╝    //
//    ██║   ██║██║     █████╗      //
//    ██║   ██║██║     ██╔══╝      //
//    ╚██████╔╝╚██████╗██║         //
//     ╚═════╝  ╚═════╝╚═╝         //
//                                 //
//             by                  //
//                                 //
//       TimTimFansFans            //
//                                 //
//                                 //
/////////////////////////////////////


contract UCF is ERC1155Creator {
    constructor() ERC1155Creator("Ultimate Cock Fights by TTFF", "UCF") {}
}
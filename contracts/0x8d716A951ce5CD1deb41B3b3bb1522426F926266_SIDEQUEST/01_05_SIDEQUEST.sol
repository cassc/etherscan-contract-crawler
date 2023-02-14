// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Sidequest
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//             _______________          //
//        ()==(               (+==()    //
//             '______________'|        //
//               |             |        //
//               | THE JOURNEY |        //
//               |    AWAITS   |        //
//             __)_____________|        //
//        ()==(               (+==()    //
//             '--------------'         //
//                                      //
//                                      //
//////////////////////////////////////////


contract SIDEQUEST is ERC1155Creator {
    constructor() ERC1155Creator("The Sidequest", "SIDEQUEST") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HXXDIE BLVCK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     __  __        __  __                  //
//    /\_\_\_\      /\_\_\_\                 //
//    \/_/\_\/_     \/_/\_\/_                //
//      /\_\/\_\      /\_\/\_\               //
//      \/_/\/_/      \/_/\/_/               //
//                                           //
//     __     __     __     __     __        //
//    /\ \   /\ \   /\ \   /\ \   /\ \       //
//    \ \ \  \ \ \  \ \ \  \ \ \  \ \ \      //
//     \ \_\  \ \_\  \ \_\  \ \_\  \ \_\     //
//      \/_/   \/_/   \/_/   \/_/   \/_/     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract HXXD is ERC1155Creator {
    constructor() ERC1155Creator("HXXDIE BLVCK", "HXXD") {}
}
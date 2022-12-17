// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MVP Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//             ___                         //
//           [|     |=|{)__                //
//            |___|    \/   )              //
//             /|\     /|                  //
//            / | \    | \          MVP    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract MVPEDITIONS is ERC1155Creator {
    constructor() ERC1155Creator("MVP Editions", "MVPEDITIONS") {}
}
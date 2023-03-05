// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chowls
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//                                     //
//     CCC H  H  OOO  W     W L        //
//    C    H  H O   O W     W L        //
//    C    HHHH O   O W  W  W L        //
//    C    H  H O   O  W W W  L        //
//     CCC H  H  OOO    W W   LLLL     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract CHOWL is ERC1155Creator {
    constructor() ERC1155Creator("Chowls", "CHOWL") {}
}
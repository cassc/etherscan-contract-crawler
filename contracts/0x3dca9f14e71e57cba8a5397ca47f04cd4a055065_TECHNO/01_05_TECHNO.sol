// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 808FM 001
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     #####    ###    #####     ####### #     #     //
//    #     #  #   #  #     #    #       ##   ##     //
//    #     # #     # #     #    #       # # # #     //
//     #####  #     #  #####     #####   #  #  #     //
//    #     # #     # #     #    #       #     #     //
//    #     #  #   #  #     #    #       #     #     //
//     #####    ###    #####     #       #     #     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract TECHNO is ERC1155Creator {
    constructor() ERC1155Creator("808FM 001", "TECHNO") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pain Originals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    ### #######    #     # #     # ######  #######  #####      //
//     #     #       #     # #     # #     #    #    #     #     //
//     #     #       #     # #     # #     #    #    #           //
//     #     #       ####### #     # ######     #     #####      //
//     #     #       #     # #     # #   #      #          #     //
//     #     #       #     # #     # #    #     #    #     #     //
//    ###    #       #     #  #####  #     #    #     #####      //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract PAIN is ERC721Creator {
    constructor() ERC721Creator("Pain Originals", "PAIN") {}
}
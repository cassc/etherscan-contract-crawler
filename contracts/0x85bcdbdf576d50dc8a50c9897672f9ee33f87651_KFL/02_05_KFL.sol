// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: i keep forgetting to live
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ### #    # #######  #####  #           //
//     #  #   #  #       #     # #           //
//     #  #  #   #             # #           //
//     #  ###    #####    #####  #           //
//     #  #  #   #       #       #           //
//     #  #   #  #       #       #           //
//    ### #    # #       ####### #######     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract KFL is ERC721Creator {
    constructor() ERC721Creator("i keep forgetting to live", "KFL") {}
}
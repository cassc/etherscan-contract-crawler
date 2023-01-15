// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dylan Kowalski Artwork
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    ######  #    #    #        //
//    #     # #   #    # #       //
//    #     # #  #    #   #      //
//    #     # ###    #     #     //
//    #     # #  #   #######     //
//    #     # #   #  #     #     //
//    ######  #    # #     #     //
//                               //
//                               //
///////////////////////////////////


contract DKA is ERC721Creator {
    constructor() ERC721Creator("Dylan Kowalski Artwork", "DKA") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PURU
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    ######  #     # ######  #     #     //
//    #     # #     # #     # #     #     //
//    #     # #     # #     # #     #     //
//    ######  #     # ######  #     #     //
//    #       #     # #   #   #     #     //
//    #       #     # #    #  #     #     //
//    #        #####  #     #  #####      //
//                                        //
//                                        //
////////////////////////////////////////////


contract PURU is ERC721Creator {
    constructor() ERC721Creator("PURU", "PURU") {}
}
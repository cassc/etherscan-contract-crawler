// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Symphony
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//     #####                                                     //
//    #     # #   # #    # #####  #    #  ####  #    # #   #     //
//    #        # #  ##  ## #    # #    # #    # ##   #  # #      //
//     #####    #   # ## # #    # ###### #    # # #  #   #       //
//          #   #   #    # #####  #    # #    # #  # #   #       //
//    #     #   #   #    # #      #    # #    # #   ##   #       //
//     #####    #   #    # #      #    #  ####  #    #   #       //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract SYM is ERC721Creator {
    constructor() ERC721Creator("Symphony", "SYM") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: thumb cinema
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ##### #    # #    # #    # #####         //
//      #   #    # #    # ##  ## #    #        //
//      #   ###### #    # # ## # #####         //
//      #   #    # #    # #    # #    #        //
//      #   #    # #    # #    # #    #        //
//      #   #    #  ####  #    # #####         //
//                                             //
//                                             //
//     ####  # #    # ###### #    #   ##       //
//    #    # # ##   # #      ##  ##  #  #      //
//    #      # # #  # #####  # ## # #    #     //
//    #      # #  # # #      #    # ######     //
//    #    # # #   ## #      #    # #    #     //
//     ####  # #    # ###### #    # #    #     //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract DOSTC is ERC721Creator {
    constructor() ERC721Creator("thumb cinema", "DOSTC") {}
}
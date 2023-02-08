// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MyCactus
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    #     #        #####                                        //
//    ##   ## #   # #     #   ##    ####  ##### #    #  ####      //
//    # # # #  # #  #        #  #  #    #   #   #    # #          //
//    #  #  #   #   #       #    # #        #   #    #  ####      //
//    #     #   #   #       ###### #        #   #    #      #     //
//    #     #   #   #     # #    # #    #   #   #    # #    #     //
//    #     #   #    #####  #    #  ####    #    ####   ####      //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract Cactus is ERC721Creator {
    constructor() ERC721Creator("MyCactus", "Cactus") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Corporate  Labyrinth
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    #                                                            //
//    #         ##   #####  #   # #####  # #    # ##### #    #     //
//    #        #  #  #    #  # #  #    # # ##   #   #   #    #     //
//    #       #    # #####    #   #    # # # #  #   #   ######     //
//    #       ###### #    #   #   #####  # #  # #   #   #    #     //
//    #       #    # #    #   #   #   #  # #   ##   #   #    #     //
//    ####### #    # #####    #   #    # # #    #   #   #    #     //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract Labyrinth is ERC1155Creator {
    constructor() ERC1155Creator("Corporate  Labyrinth", "Labyrinth") {}
}
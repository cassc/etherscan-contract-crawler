// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: David Manns
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    ######  ######     #     #                                 //
//    #     # #     #    ##   ##   ##   #    # #    #  ####      //
//    #     # #     #    # # # #  #  #  ##   # ##   # #          //
//    #     # ######     #  #  # #    # # #  # # #  #  ####      //
//    #     # #          #     # ###### #  # # #  # #      #     //
//    #     # #          #     # #    # #   ## #   ## #    #     //
//    ######  #          #     # #    # #    # #    #  ####      //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract MANNS is ERC721Creator {
    constructor() ERC721Creator("David Manns", "MANNS") {}
}
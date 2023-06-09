// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Indication Of Red: Dissolution
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    ######                                                                 //
//    #     # #  ####   ####   ####  #      #    # ##### #  ####  #    #     //
//    #     # # #      #      #    # #      #    #   #   # #    # ##   #     //
//    #     # #  ####   ####  #    # #      #    #   #   # #    # # #  #     //
//    #     # #      #      # #    # #      #    #   #   # #    # #  # #     //
//    #     # # #    # #    # #    # #      #    #   #   # #    # #   ##     //
//    ######  #  ####   ####   ####  ######  ####    #   #  ####  #    #     //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract Red is ERC1155Creator {
    constructor() ERC1155Creator("Indication Of Red: Dissolution", "Red") {}
}
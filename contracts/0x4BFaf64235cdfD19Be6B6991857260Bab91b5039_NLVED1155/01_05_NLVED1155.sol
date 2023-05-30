// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NLV Editions 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    #     # #       #     #    ####### ######   #####      //
//    ##    # #       #     #    #       #     # #     #     //
//    # #   # #       #     #    #       #     #       #     //
//    #  #  # #       #     #    #####   #     #  #####      //
//    #   # # #        #   #     #       #     # #           //
//    #    ## #         # #      #       #     # #           //
//    #     # #######    #       ####### ######  #######     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract NLVED1155 is ERC1155Creator {
    constructor() ERC1155Creator("NLV Editions 1155", "NLVED1155") {}
}
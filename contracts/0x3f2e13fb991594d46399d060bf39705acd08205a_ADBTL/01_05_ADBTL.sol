// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Day by the Lake
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//       #    ######  ######  ####### #           //
//      # #   #     # #     #    #    #           //
//     #   #  #     # #     #    #    #           //
//    #     # #     # ######     #    #           //
//    ####### #     # #     #    #    #           //
//    #     # #     # #     #    #    #           //
//    #     # ######  ######     #    #######     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ADBTL is ERC721Creator {
    constructor() ERC721Creator("A Day by the Lake", "ADBTL") {}
}
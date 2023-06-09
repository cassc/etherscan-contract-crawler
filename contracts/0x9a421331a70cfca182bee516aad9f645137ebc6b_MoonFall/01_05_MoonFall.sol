// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moon Fall
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    #     #                         #######                          //
//    ##   ##  ####   ####  #    #    #         ##   #      #          //
//    # # # # #    # #    # ##   #    #        #  #  #      #          //
//    #  #  # #    # #    # # #  #    #####   #    # #      #          //
//    #     # #    # #    # #  # #    #       ###### #      #          //
//    #     # #    # #    # #   ##    #       #    # #      #          //
//    #     #  ####   ####  #    #    #       #    # ###### ######     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract MoonFall is ERC1155Creator {
    constructor() ERC1155Creator("Moon Fall", "MoonFall") {}
}
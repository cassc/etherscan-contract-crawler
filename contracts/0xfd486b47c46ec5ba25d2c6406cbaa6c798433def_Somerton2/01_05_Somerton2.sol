// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Somerton Man Episode 2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//     #####                                                   #####      //
//    #     #  ####  #    # ###### #####  #####  ####  #    # #     #     //
//    #       #    # ##  ## #      #    #   #   #    # ##   #       #     //
//     #####  #    # # ## # #####  #    #   #   #    # # #  #  #####      //
//          # #    # #    # #      #####    #   #    # #  # # #           //
//    #     # #    # #    # #      #   #    #   #    # #   ## #           //
//     #####   ####  #    # ###### #    #   #    ####  #    # #######     //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract Somerton2 is ERC1155Creator {
    constructor() ERC1155Creator("Somerton Man Episode 2", "Somerton2") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 639 Hertz Alien Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//     #####   #####   #####     #     #                                  #                                 #                     //
//    #     # #     # #     #    #     # ###### #####  ##### ######      # #   #      # ###### #    #      # #   #####  #####     //
//    #             # #     #    #     # #      #    #   #       #      #   #  #      # #      ##   #     #   #  #    #   #       //
//    ######   #####   ######    ####### #####  #    #   #      #      #     # #      # #####  # #  #    #     # #    #   #       //
//    #     #       #       #    #     # #      #####    #     #       ####### #      # #      #  # #    ####### #####    #       //
//    #     # #     # #     #    #     # #      #   #    #    #        #     # #      # #      #   ##    #     # #   #    #       //
//     #####   #####   #####     #     # ###### #    #   #   ######    #     # ###### # ###### #    #    #     # #    #   #       //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Hz is ERC721Creator {
    constructor() ERC721Creator("639 Hertz Alien Art", "Hz") {}
}
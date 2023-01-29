// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strokez
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//     ####  ##### #####   ####  #    # ###### ######     //
//    #        #   #    # #    # #   #  #          #      //
//     ####    #   #    # #    # ####   #####     #       //
//         #   #   #####  #    # #  #   #        #        //
//    #    #   #   #   #  #    # #   #  #       #         //
//     ####    #   #    #  ####  #    # ###### ######     //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract STRO is ERC1155Creator {
    constructor() ERC1155Creator("Strokez", "STRO") {}
}
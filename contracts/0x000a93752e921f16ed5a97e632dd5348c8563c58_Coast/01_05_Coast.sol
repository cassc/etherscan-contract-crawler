// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Coastal Lone Time
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    #####                                  //
//    #     #  ####    ##    ####  #####     //
//    #       #    #  #  #  #        #       //
//    #       #    # #    #  ####    #       //
//    #       #    # ######      #   #       //
//    #     # #    # #    # #    #   #       //
//     #####   ####  #    #  ####    #       //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Coast is ERC1155Creator {
    constructor() ERC1155Creator("Coastal Lone Time", "Coast") {}
}
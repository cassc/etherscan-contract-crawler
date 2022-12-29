// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: noelhefele editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    #    #  ####  ###### #          //
//    ##   # #    # #      #          //
//    # #  # #    # #####  #          //
//    #  # # #    # #      #          //
//    #   ## #    # #      #          //
//    #    #  ####  ###### ######     //
//                                    //
//                                    //
////////////////////////////////////////


contract noel1 is ERC721Creator {
    constructor() ERC721Creator("noelhefele editions", "noel1") {}
}
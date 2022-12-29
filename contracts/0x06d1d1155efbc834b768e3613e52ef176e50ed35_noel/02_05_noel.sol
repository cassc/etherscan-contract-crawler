// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: noelhefele
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


contract noel is ERC721Creator {
    constructor() ERC721Creator("noelhefele", "noel") {}
}
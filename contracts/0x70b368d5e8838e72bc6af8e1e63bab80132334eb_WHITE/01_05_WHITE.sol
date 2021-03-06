// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mr. White
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    ######                                                            //
//    #     # ###### #    #  ####  ##### #####    ##   #   #  ####      //
//    #     # #      ##  ## #        #   #    #  #  #   # #  #          //
//    #     # #####  # ## #  ####    #   #    # #    #   #    ####      //
//    #     # #      #    #      #   #   #####  ######   #        #     //
//    #     # #      #    # #    #   #   #   #  #    #   #   #    #     //
//    ######  ###### #    #  ####    #   #    # #    #   #    ####      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract WHITE is ERC721Creator {
    constructor() ERC721Creator("Mr. White", "WHITE") {}
}
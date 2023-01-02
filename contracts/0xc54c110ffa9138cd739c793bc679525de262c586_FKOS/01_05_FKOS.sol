// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FCKOS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ####### #     #  #####  #    #    #######  #####      //
//    #       #     # #     # #   #     #     # #     #     //
//    #       #     # #       #  #      #     # #           //
//    #####   #     # #       ###       #     #  #####      //
//    #       #     # #       #  #      #     #       #     //
//    #       #     # #     # #   #     #     # #     #     //
//    #        #####   #####  #    #    #######  #####      //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract FKOS is ERC721Creator {
    constructor() ERC721Creator("FCKOS", "FKOS") {}
}
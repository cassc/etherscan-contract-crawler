// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Specs VV Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    #####    ####    ####    ####    //
//    #     #  #   #  #       #        //
//    #     #  #   #  #       #        //
//    #####   #   #   ####    ####     //
//    #       #   #      #       #     //
//    #       #   #      #       #     //
//    #        ####    ####    ####    //
//                                     //
//                                     //
/////////////////////////////////////////


contract SPEC is ERC721Creator {
    constructor() ERC721Creator("Specs VV Edition", "SPEC") {}
}
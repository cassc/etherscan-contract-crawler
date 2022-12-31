// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Matau Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     #    #    ##     #####    ##    #    #    //
//     ##  ##   #  #      #     #  #   #    #    //
//     # ## #  #    #     #    #    #  #    #    //
//     #    #  ######     #    ######  #    #    //
//     #    #  #    #     #    #    #  #    #    //
//     #    #  #    #     #    #    #   ####     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MATAU is ERC1155Creator {
    constructor() ERC1155Creator("Matau Art", "MATAU") {}
}
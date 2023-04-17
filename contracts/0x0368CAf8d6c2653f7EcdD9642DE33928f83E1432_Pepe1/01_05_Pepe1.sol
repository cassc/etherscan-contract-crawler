// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Through Time 1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ######                           //
//    #     # ###### #####  ######     //
//    #     # #      #    # #          //
//    ######  #####  #    # #####      //
//    #       #      #####  #          //
//    #       #      #      #          //
//    #       ###### #      ######     //
//                                     //
//                                     //
/////////////////////////////////////////


contract Pepe1 is ERC1155Creator {
    constructor() ERC1155Creator("Pepe Through Time 1", "Pepe1") {}
}
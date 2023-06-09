// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE THROUGH TIME 2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ######                           #####      //
//    #     # ###### #####  ######    #     #     //
//    #     # #      #    # #               #     //
//    ######  #####  #    # #####      #####      //
//    #       #      #####  #         #           //
//    #       #      #      #         #           //
//    #       ###### #      ######    #######     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract Pepe2 is ERC1155Creator {
    constructor() ERC1155Creator("PEPE THROUGH TIME 2", "Pepe2") {}
}
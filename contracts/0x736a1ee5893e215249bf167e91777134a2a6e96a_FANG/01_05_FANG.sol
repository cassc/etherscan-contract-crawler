// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fang's photography
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ######   ##   #    #  ####      //
//    #       #  #  ##   # #    #     //
//    #####  #    # # #  # #          //
//    #      ###### #  # # #  ###     //
//    #      #    # #   ## #    #     //
//    #      #    # #    #  ####      //
//                                    //
//                                    //
////////////////////////////////////////


contract FANG is ERC1155Creator {
    constructor() ERC1155Creator("Fang's photography", "FANG") {}
}
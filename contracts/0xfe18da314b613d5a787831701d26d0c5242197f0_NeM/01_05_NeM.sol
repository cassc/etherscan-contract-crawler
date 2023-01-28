// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neon in Motion
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    #    # ######  ####  #    #     //
//    ##   # #      #    # ##   #     //
//    # #  # #####  #    # # #  #     //
//    #  # # #      #    # #  # #     //
//    #   ## #      #    # #   ##     //
//    #    # ######  ####  #    #     //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract NeM is ERC1155Creator {
    constructor() ERC1155Creator("Neon in Motion", "NeM") {}
}
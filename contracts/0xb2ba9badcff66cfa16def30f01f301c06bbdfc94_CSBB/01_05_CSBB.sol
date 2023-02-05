// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chinese Spy Balloon Boy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    #####  # #####  ####   ####  # #    #  ####  #    # #     //
//    #    # #   #   #    # #    # # ##   # #      #   #  #     //
//    #####  #   #   #      #    # # # #  #  ####  ####   #     //
//    #    # #   #   #      #    # # #  # #      # #  #   #     //
//    #    # #   #   #    # #    # # #   ## #    # #   #  #     //
//    #####  #   #    ####   ####  # #    #  ####  #    # #     //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract CSBB is ERC1155Creator {
    constructor() ERC1155Creator("Chinese Spy Balloon Boy", "CSBB") {}
}
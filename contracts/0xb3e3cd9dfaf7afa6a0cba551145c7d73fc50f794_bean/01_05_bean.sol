// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: beans
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                                            //
//     #####  ######   ##   #    #  ####      //
//     #    # #       #  #  ##   # #          //
//     #####  #####  #    # # #  #  ####      //
//     #    # #      ###### #  # #      #     //
//     #    # #      #    # #   ## #    #     //
//     #####  ###### #    # #    #  ####      //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract bean is ERC721Creator {
    constructor() ERC721Creator("beans", "bean") {}
}
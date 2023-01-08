// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Greatest Player of All Time
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    #     # #######  #####   #####  ###     //
//    ##   ## #       #     # #     #  #      //
//    # # # # #       #       #        #      //
//    #  #  # #####    #####   #####   #      //
//    #     # #             #       #  #      //
//    #     # #       #     # #     #  #      //
//    #     # #######  #####   #####  ###     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract GOAT is ERC721Creator {
    constructor() ERC721Creator("The Greatest Player of All Time", "GOAT") {}
}
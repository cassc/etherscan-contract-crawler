// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nickjrufo's 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//    ###  ## ##      //
//    # #   # # #     //
//    # #   # ##      //
//    # # # # # #     //
//    # #  #  # #     //
//                    //
//     #    #  #      //
//    ##    # ##      //
//     #   #   #      //
//     #  #    #      //
//    ### #   ###     //
//                    //
//                    //
//                    //
////////////////////////


contract NJR is ERC721Creator {
    constructor() ERC721Creator("nickjrufo's 1/1s", "NJR") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimal cars
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//     #######                                                  //
//     #     #                                                  //
//     #        #######  #######  #        #     #     #        //
//     #######     #     #     #  #        ##   ##     #        //
//          ##     #     #######  #        # # # #     #        //
//     #    ##     #     #     #  #        #  #  #     #        //
//     #######     #     #     #  #######  #     #     #        //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract MinC is ERC721Creator {
    constructor() ERC721Creator("Minimal cars", "MinC") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lucy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    #       #     #  #####  #     #     //
//    #       #     # #     #  #   #      //
//    #       #     # #         # #       //
//    #       #     # #          #        //
//    #       #     # #          #        //
//    #       #     # #     #    #        //
//    #######  #####   #####     #        //
//                                        //
//                                        //
////////////////////////////////////////////


contract lucy is ERC721Creator {
    constructor() ERC721Creator("lucy", "lucy") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: House Of Dorsey
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    #     # ####### ######      //
//    #     # #     # #     #     //
//    #     # #     # #     #     //
//    ####### #     # #     #     //
//    #     # #     # #     #     //
//    #     # #     # #     #     //
//    #     # ####### ######      //
//                                //
//                                //
//                                //
////////////////////////////////////


contract HOD is ERC721Creator {
    constructor() ERC721Creator("House Of Dorsey", "HOD") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SGMX721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    ////////////////////////                   //
//    //                                         //
//    //                                         //
//    //    SIGMAX 721                           //
//    //    1/1 contract                         //
//    //                                         //
//    //                                         //
//    //                                         //
//    ////////////////////////                   //
//                           //                  //
//                           //                  //
//        SIGMAX 721         //                  //
//        1/1 contract       //                  //
//                           //                  //
//                           //                  //
//                           //                  //
//    ////////////////////////                   //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract sgmx721 is ERC721Creator {
    constructor() ERC721Creator("SGMX721", "sgmx721") {}
}
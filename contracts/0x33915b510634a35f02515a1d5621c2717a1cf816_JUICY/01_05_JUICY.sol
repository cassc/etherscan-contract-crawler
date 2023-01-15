// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hbd kat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    /////////////////////////////////    //
//    //                             //    //
//    //                             //    //
//    //                             //    //
//    //      .             .        //    //
//    //       |. .* _.  .   |. .    //    //
//    //    \__|(_||(_.\_|\__|(_|    //    //
//    //               ._|           //    //
//    //                             //    //
//    //                             //    //
//    //                             //    //
//    /////////////////////////////////    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract JUICY is ERC721Creator {
    constructor() ERC721Creator("hbd kat", "JUICY") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nature AI Human by Korbinian Vogt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    /////////////////////////////////////////////    //
//    //                                         //    //
//    //                                         //    //
//    //    Nature AI Human by Korbinian Vogt    //    //
//    //                                         //    //
//    //                                         //    //
//    /////////////////////////////////////////////    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract NAIBBKV is ERC721Creator {
    constructor() ERC721Creator("Nature AI Human by Korbinian Vogt", "NAIBBKV") {}
}
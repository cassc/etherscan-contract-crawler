// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kdeneufchatel
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     ____  __.________       //
//    |    |/ _|\______ \      //
//    |      <   |    |  \     //
//    |    |  \  |    `   \    //
//    |____|__ \/_______  /    //
//            \/        \/     //
//                             //
//                             //
/////////////////////////////////


contract PRTW3 is ERC721Creator {
    constructor() ERC721Creator("kdeneufchatel", "PRTW3") {}
}
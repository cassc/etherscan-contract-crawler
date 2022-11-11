// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: instant moments
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    dieLehmanns - instant moments    //
//                                     //
//                                     //
/////////////////////////////////////////


contract dLehIM is ERC721Creator {
    constructor() ERC721Creator("instant moments", "dLehIM") {}
}
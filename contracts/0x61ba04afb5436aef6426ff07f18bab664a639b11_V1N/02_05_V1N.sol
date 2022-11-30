// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: V1NCENT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    THRE ART OF V1NCENT    //
//                           //
//                           //
///////////////////////////////


contract V1N is ERC721Creator {
    constructor() ERC721Creator("V1NCENT", "V1N") {}
}
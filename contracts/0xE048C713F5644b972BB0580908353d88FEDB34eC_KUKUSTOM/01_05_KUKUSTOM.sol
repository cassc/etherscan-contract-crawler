// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KUSO KUSTOM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    KUSO KUSTOMS by KAY    //
//                           //
//                           //
///////////////////////////////


contract KUKUSTOM is ERC721Creator {
    constructor() ERC721Creator("KUSO KUSTOM", "KUKUSTOM") {}
}
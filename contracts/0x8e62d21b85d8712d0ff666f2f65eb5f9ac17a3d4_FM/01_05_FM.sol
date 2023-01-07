// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fantasy Woman
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    -CryptoArtis-    //
//                     //
//                     //
/////////////////////////


contract FM is ERC721Creator {
    constructor() ERC721Creator("Fantasy Woman", "FM") {}
}
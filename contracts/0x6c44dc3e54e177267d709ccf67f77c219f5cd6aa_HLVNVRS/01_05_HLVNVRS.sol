// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Helluva's Universe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    _  _ _   _   _       //
//    | || | | | \ / |     //
//    | >< | |_`\ V /'     //
//    |_||_|___| \_/       //
//                         //
//                         //
/////////////////////////////


contract HLVNVRS is ERC721Creator {
    constructor() ERC721Creator("Helluva's Universe", "HLVNVRS") {}
}
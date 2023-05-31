// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CIPX 721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    :-)    //
//    /|\    //
//    / \    //
//           //
//           //
///////////////


contract CIPX721 is ERC721Creator {
    constructor() ERC721Creator("CIPX 721", "CIPX721") {}
}
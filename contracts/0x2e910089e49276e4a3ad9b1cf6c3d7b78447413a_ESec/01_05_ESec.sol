// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Every Second
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Every Second    //
//                    //
//                    //
////////////////////////


contract ESec is ERC721Creator {
    constructor() ERC721Creator("Every Second", "ESec") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: What is Drip: The Legend of The Big Gooey
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    The Big Gooey    //
//                     //
//                     //
/////////////////////////


contract TBG is ERC721Creator {
    constructor() ERC721Creator("What is Drip: The Legend of The Big Gooey", "TBG") {}
}
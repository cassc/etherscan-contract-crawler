// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wtf will you get?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    who needs ascii art?    //
//                            //
//                            //
////////////////////////////////


contract idk is ERC1155Creator {
    constructor() ERC1155Creator("Wtf will you get?", "idk") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eddie Gangland Originals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Eddie Gangland Originals    //
//                                //
//                                //
////////////////////////////////////


contract GANGORIGINAL is ERC721Creator {
    constructor() ERC721Creator("Eddie Gangland Originals", "GANGORIGINAL") {}
}
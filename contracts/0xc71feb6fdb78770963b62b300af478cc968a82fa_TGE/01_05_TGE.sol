// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Grand Embrace
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    The first ever Open Edition by Viulet    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract TGE is ERC721Creator {
    constructor() ERC721Creator("The Grand Embrace", "TGE") {}
}
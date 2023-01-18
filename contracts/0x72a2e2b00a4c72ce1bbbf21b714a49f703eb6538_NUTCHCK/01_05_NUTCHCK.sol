// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PATNUTCHECK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    PATNUT CHECKS    //
//                     //
//                     //
/////////////////////////


contract NUTCHCK is ERC721Creator {
    constructor() ERC721Creator("PATNUTCHECK", "NUTCHCK") {}
}
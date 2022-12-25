// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Merry Christmas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    Happy      //
//    HoliDay    //
//               //
//               //
///////////////////


contract MC is ERC721Creator {
    constructor() ERC721Creator("Merry Christmas", "MC") {}
}
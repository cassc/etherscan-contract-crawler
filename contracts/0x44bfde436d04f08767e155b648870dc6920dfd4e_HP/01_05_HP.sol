// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Historical Pepes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    The Big Gooey    //
//                     //
//                     //
/////////////////////////


contract HP is ERC721Creator {
    constructor() ERC721Creator("Historical Pepes", "HP") {}
}
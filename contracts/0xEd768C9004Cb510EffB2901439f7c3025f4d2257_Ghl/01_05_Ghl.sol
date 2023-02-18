// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghoul Kid
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    Ghost Kid    //
//                 //
//                 //
/////////////////////


contract Ghl is ERC1155Creator {
    constructor() ERC1155Creator("Ghoul Kid", "Ghl") {}
}
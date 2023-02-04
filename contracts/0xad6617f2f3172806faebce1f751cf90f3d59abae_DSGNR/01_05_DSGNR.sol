// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DSGNR
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    888 88e      dP"8     e88'Y88    Y88b Y88   888 88e      //
//    888 888b    C8b Y    d888  'Y     Y88b Y8   888 888D     //
//    888 8888D    Y8b    C8888 eeee   b Y88b Y   888 88"      //
//    888 888P    b Y8D    Y888 888P   8b Y88b    888 b,       //
//    888 88"     8edP      "88 88"    88b Y88b   888 88b,     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract DSGNR is ERC1155Creator {
    constructor() ERC1155Creator("DSGNR", "DSGNR") {}
}
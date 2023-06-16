// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Good Luck Charms
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    REEEEEEEEEEEEEEEEEEEEE MEMES    //
//                                    //
//                                    //
////////////////////////////////////////


contract GLC is ERC1155Creator {
    constructor() ERC1155Creator("Good Luck Charms", "GLC") {}
}
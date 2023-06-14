// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phases of The Moon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//    |^ |-| /\ _\~ [- _\~   () /=   ~|~ |-| [-   |\/| () () |\|     //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract POTM is ERC1155Creator {
    constructor() ERC1155Creator("Phases of The Moon", "POTM") {}
}
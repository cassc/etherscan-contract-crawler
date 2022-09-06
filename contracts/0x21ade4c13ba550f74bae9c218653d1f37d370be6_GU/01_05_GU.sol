// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Genuine Undead
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                               //
//                                                                                                                                                                               //
//    24*24 pixel PFP you have never seen. 5995 classic, 3996 cyberpunk and 8 legendary, over 200 hand draw traits, rich variety. ERC-721A contract. RISE AND SHINE together.    //
//                                                                                                                                                                               //
//                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GU is ERC721Creator {
    constructor() ERC721Creator("Genuine Undead", "GU") {}
}
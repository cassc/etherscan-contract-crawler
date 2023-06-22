// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kallenia AI Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    |/ _ || _  _ . _    /\ ~|~   /\  __|_    //
//    |\(_|||(/_| ||(_|  /~~\_|_  /~~\|  |     //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract KAAI is ERC721Creator {
    constructor() ERC721Creator("Kallenia AI Art", "KAAI") {}
}
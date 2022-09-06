// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bucket Hat Gang Patron Token
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    [Creator of community connected art] Not verified but the ᵍᵐ is better anyway.    //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract BHG is ERC721Creator {
    constructor() ERC721Creator("Bucket Hat Gang Patron Token", "BHG") {}
}
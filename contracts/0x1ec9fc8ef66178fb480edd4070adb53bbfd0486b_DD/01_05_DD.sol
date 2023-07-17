// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Defi Darling
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    A limited edition 1-1 of me embracing the power of the human body and it's art form.     //
//                                                                                             //
//                                                                                             //
//    Support me with my business endeavours and my selected charity                           //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract DD is ERC721Creator {
    constructor() ERC721Creator("Defi Darling", "DD") {}
}
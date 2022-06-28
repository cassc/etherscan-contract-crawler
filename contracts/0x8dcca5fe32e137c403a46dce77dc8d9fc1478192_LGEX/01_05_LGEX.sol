// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Ledge Exclusives
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    A Collections created to home the Exclusive drops on The Ledge.     //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract LGEX is ERC721Creator {
    constructor() ERC721Creator("The Ledge Exclusives", "LGEX") {}
}
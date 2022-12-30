// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Artist Named Unk
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    The Artist Named Unk    //
//                            //
//                            //
////////////////////////////////


contract Unk is ERC721Creator {
    constructor() ERC721Creator("The Artist Named Unk", "Unk") {}
}
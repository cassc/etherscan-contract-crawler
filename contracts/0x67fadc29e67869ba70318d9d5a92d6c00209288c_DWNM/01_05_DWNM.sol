// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DWNM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//     __                     //
//    |  \ |  | |\ | |\/|     //
//    |__/ |/\| | \| |  |     //
//                            //
//                            //
//                            //
////////////////////////////////


contract DWNM is ERC721Creator {
    constructor() ERC721Creator("DWNM", "DWNM") {}
}
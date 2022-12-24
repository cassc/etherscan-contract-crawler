// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOT 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//     ____      /\  ____     //
//    /_   |    / / /_   |    //
//     |   |   / /   |   |    //
//     |   |  / /    |   |    //
//     |___| / /     |___|    //
//           \/               //
//                            //
//                            //
//                            //
////////////////////////////////


contract NOT is ERC721Creator {
    constructor() ERC721Creator("NOT 1/1s", "NOT") {}
}
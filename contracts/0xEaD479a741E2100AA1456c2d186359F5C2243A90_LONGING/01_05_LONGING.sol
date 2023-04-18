// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Longing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//         _        __ ___       __     //
//     |  / \ |\ | /__  |  |\ | /__     //
//     |_ \_/ | \| \_| _|_ | \| \_|     //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract LONGING is ERC721Creator {
    constructor() ERC721Creator("Longing", "LONGING") {}
}
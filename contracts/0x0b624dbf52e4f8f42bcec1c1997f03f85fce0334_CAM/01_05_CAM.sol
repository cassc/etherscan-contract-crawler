// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Circle Art by Mua
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    Pure ring art. Just vibe and have fun. Twitter coming soon...    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract CAM is ERC721Creator {
    constructor() ERC721Creator("Circle Art by Mua", "CAM") {}
}
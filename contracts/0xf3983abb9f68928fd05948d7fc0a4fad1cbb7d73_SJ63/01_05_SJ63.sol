// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sonja's Watercolor Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     ____   __   __ _    __   __      //
//    / ___) /  \ (  ( \ _(  ) / _\     //
//    \___ \(  O )/    // \) \/    \    //
//    (____/ \__/ \_)__)\____/\_/\_/    //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract SJ63 is ERC721Creator {
    constructor() ERC721Creator("Sonja's Watercolor Collection", "SJ63") {}
}
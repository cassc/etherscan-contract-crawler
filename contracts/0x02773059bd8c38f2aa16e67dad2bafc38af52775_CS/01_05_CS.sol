// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chemical Smirk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//        __ _____    //
//       /  ] ___/    //
//      /  (   \_     //
//     /  / \__  |    //
//    /   \_/  \ |    //
//    \     \    |    //
//     \____|\___|    //
//                    //
//                    //
//                    //
//                    //
////////////////////////


contract CS is ERC721Creator {
    constructor() ERC721Creator("Chemical Smirk", "CS") {}
}
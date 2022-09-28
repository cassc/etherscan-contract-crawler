// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitch Studies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//     ● ● ● ● ● ● ● ● ● ●     //
//                             //
//                             //
/////////////////////////////////


contract GLTCHS is ERC721Creator {
    constructor() ERC721Creator("Glitch Studies", "GLTCHS") {}
}
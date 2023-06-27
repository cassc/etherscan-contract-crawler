// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Out of the Rain
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    ~~~888~~~   ,88~-_   ,d88~~\ ,d88~~\        e      888     //
//       888     d888   \  8888    8888          d8b     888     //
//       888    88888    | `Y88b   `Y88b        /Y88b    888     //
//       888    88888    |  `Y88b,  `Y88b,     /  Y88b   888     //
//       888     Y888   /     8888    8888    /____Y88b  888     //
//       888      `88_-~   \__88P' \__88P'   /      Y88b 888     //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract TossAi is ERC721Creator {
    constructor() ERC721Creator("Out of the Rain", "TossAi") {}
}
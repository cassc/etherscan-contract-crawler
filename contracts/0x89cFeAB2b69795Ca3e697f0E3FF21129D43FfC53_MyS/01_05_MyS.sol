// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mysterious Spaceship
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    (●'◡'●)    //
//               //
//               //
///////////////////


contract MyS is ERC721Creator {
    constructor() ERC721Creator("Mysterious Spaceship", "MyS") {}
}
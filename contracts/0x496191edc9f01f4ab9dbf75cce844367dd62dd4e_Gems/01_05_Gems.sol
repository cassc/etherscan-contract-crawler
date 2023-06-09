// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pastas Temple
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    1 of 1 works    //
//                    //
//                    //
//                    //
////////////////////////


contract Gems is ERC721Creator {
    constructor() ERC721Creator("Pastas Temple", "Gems") {}
}
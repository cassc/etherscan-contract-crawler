// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Friendship♥
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    ꧁•⊹٭𝙵𝚁𝙸𝙴𝙽𝙳𝚂𝙷𝙸𝙿٭⊹•꧂    //
//                                    //
//                                    //
////////////////////////////////////////


contract Folky is ERC721Creator {
    constructor() ERC721Creator(unicode"Friendship♥", "Folky") {}
}
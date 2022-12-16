// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toby Kurtzz Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     ___  ___  ___  _ _   _ __ _ _  ___  ___  ____ ____    //
//    |_ _|| . || . >| | | | / /| | || . \|_ _||_  /|_  /    //
//     | | | | || . \\   / |  \ | ' ||   / | |  / /  / /     //
//     |_| `___'|___/ |_|  |_\_\`___'|_\_\ |_| /___|/___|    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract TKP is ERC721Creator {
    constructor() ERC721Creator("Toby Kurtzz Photography", "TKP") {}
}
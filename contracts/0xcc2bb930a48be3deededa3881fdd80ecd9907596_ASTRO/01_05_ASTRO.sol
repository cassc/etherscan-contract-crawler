// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Astral
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//       _____            __                .__       //
//      /  _  \   _______/  |_____________  |  |      //
//     /  /_\  \ /  ___/\   __\_  __ \__  \ |  |      //
//    /    |    \\___ \  |  |  |  | \// __ \|  |__    //
//    \____|__  /____  > |__|  |__|  (____  /____/    //
//            \/     \/                   \/          //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract ASTRO is ERC721Creator {
    constructor() ERC721Creator("Astral", "ASTRO") {}
}
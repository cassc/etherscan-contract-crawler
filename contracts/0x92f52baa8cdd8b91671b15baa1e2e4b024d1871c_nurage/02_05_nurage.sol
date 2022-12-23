// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mirage
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//       _____  .__                                  //
//      /     \ |__|___________     ____   ____      //
//     /  \ /  \|  \_  __ \__  \   / ___\_/ __ \     //
//    /    Y    \  ||  | \// __ \_/ /_/  >  ___/     //
//    \____|__  /__||__|  (____  /\___  / \___  >    //
//            \/               \//_____/      \/     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract nurage is ERC721Creator {
    constructor() ERC721Creator("Mirage", "nurage") {}
}
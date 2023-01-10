// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #54 on the way home, just you and me.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//       _____  .__.__   __       __                     //
//      /     \ |__|  | |  | __ _/  |_  ____ _____       //
//     /  \ /  \|  |  | |  |/ / \   __\/ __ \\__  \      //
//    /    Y    \  |  |_|    <   |  | \  ___/ / __ \_    //
//    \____|__  /__|____/__|_ \  |__|  \___  >____  /    //
//            \/             \/            \/     \/     //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract MT is ERC721Creator {
    constructor() ERC721Creator("#54 on the way home, just you and me.", "MT") {}
}
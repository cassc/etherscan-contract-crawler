// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aerie
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//       _____               .__            //
//      /  _  \   ___________|__| ____      //
//     /  /_\  \_/ __ \_  __ \  |/ __ \     //
//    /    |    \  ___/|  | \/  \  ___/     //
//    \____|__  /\___  >__|  |__|\___  >    //
//            \/     \/              \/     //
//                                          //
//                                          //
//////////////////////////////////////////////


contract AER is ERC721Creator {
    constructor() ERC721Creator("Aerie", "AER") {}
}
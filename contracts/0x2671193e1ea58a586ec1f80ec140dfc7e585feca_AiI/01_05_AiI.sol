// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art is love
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//       _____   .__ .___      //
//      /  _  \  |__||   |     //
//     /  /_\  \ |  ||   |     //
//    /    |    \|  ||   |     //
//    \____|__  /|__||___|     //
//            \/               //
//                             //
//                             //
//                             //
/////////////////////////////////


contract AiI is ERC1155Creator {
    constructor() ERC1155Creator("Art is love", "AiI") {}
}
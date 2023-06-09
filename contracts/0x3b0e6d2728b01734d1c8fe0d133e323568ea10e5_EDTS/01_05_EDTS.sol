// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     ______   ______   ______          //
//    /_____/\ /_____/\ /_____/\         //
//    \::::_\/_\:::_ \ \\::::_\/_        //
//     \:\/___/\\:\ \ \ \\:\/___/\       //
//      \::___\/_\:\ \ \ \\_::._\:\      //
//       \:\____/\\:\/.:| | /____\:\     //
//        \_____\/ \____/_/ \_____\/     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract EDTS is ERC1155Creator {
    constructor() ERC1155Creator("Editions", "EDTS") {}
}
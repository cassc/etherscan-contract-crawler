// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Angelika Ferra
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ___________                              //
//    \_   _____/______________________        //
//     |    __)/ __ \_  __ \_  __ \__  \       //
//     |     \\  ___/|  | \/|  | \// __ \_     //
//     \___  / \___  >__|   |__|  (____  /     //
//         \/      \/                  \/      //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract Ferra is ERC1155Creator {
    constructor() ERC1155Creator("Angelika Ferra", "Ferra") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arash Negahban
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//       _____                      .__         //
//      /  _  \____________    _____|  |__      //
//     /  /_\  \_  __ \__  \  /  ___/  |  \     //
//    /    |    \  | \// __ \_\___ \|   Y  \    //
//    \____|__  /__|  (____  /____  >___|  /    //
//            \/           \/     \/     \/     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract ANG is ERC721Creator {
    constructor() ERC721Creator("Arash Negahban", "ANG") {}
}
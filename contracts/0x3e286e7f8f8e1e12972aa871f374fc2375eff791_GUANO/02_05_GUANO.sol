// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Guanos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//       ______                                //
//      / ____/_  ______ _____  ____  _____    //
//     / / __/ / / / __ `/ __ \/ __ \/ ___/    //
//    / /_/ / /_/ / /_/ / / / / /_/ (__  )     //
//    \____/\__,_/\__,_/_/ /_/\____/____/      //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract GUANO is ERC721Creator {
    constructor() ERC721Creator("Guanos", "GUANO") {}
}
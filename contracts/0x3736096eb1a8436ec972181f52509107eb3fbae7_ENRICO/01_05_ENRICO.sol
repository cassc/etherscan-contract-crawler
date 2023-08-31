// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Enrico
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//        ______                    _                    //
//       / ____/  ____     _____   (_)  _____   ____     //
//      / __/    / __ \   / ___/  / /  / ___/  / __ \    //
//     / /___   / / / /  / /     / /  / /__   / /_/ /    //
//    /_____/  /_/ /_/  /_/     /_/   \___/   \____/     //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract ENRICO is ERC721Creator {
    constructor() ERC721Creator("Enrico", "ENRICO") {}
}
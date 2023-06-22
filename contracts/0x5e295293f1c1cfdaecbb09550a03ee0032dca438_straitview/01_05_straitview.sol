// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strait Views
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//              __                .__  __        //
//      _______/  |_____________  |__|/  |_      //
//     /  ___/\   __\_  __ \__  \ |  \   __\     //
//     \___ \  |  |  |  | \// __ \|  ||  |       //
//    /____  > |__|  |__|  (____  /__||__|       //
//         \/                   \/               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract straitview is ERC721Creator {
    constructor() ERC721Creator("Strait Views", "straitview") {}
}
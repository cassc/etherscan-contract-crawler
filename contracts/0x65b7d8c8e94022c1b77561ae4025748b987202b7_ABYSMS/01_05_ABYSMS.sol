// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABYSMS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//        ___    ______  _______ __  ________     //
//       /   |  / __ ) \/ / ___//  |/  / ___/     //
//      / /| | / __  |\   /\__ \/ /|_/ /\__\      //
//     / ___ |/ /_/ / / /___/ / /  / /___/ /      //
//    /_/  |_/_____/ /_//____/_/  /_//____/       //
//                                                //
//    _ on manifold                               //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ABYSMS is ERC721Creator {
    constructor() ERC721Creator("ABYSMS", "ABYSMS") {}
}
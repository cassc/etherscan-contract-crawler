// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abs90 Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                 ____     _____    ___     ___      //
//         /\     |  _ \   / ____|  / _ \   / _ \     //
//        /  \    | |_) | | (___   | (_) | | | | |    //
//       / /\ \   |  _ <   \___ \   \__, | | | | |    //
//      / ____ \  | |_) |  ____) |    / /  | |_| |    //
//     /_/    \_\ |____/  |_____/    /_/    \___/     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Abs90 is ERC1155Creator {
    constructor() ERC1155Creator("Abs90 Editions", "Abs90") {}
}
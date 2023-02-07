// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alyse Through the Looking Glass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//    A human and AI collaborating in an exploration of Self.          //
//    A collection of 1/1s by Alyse Gamson.                            //
//                                                                     //
//                                                                     //
//         _               _ _               ____  _                   //
//        | | ___   _____ | (_) __ _ _ __   |___ \| |_ __  ___ ___     //
//        | |/ _ \ / _ \ \| | |/ _` | '_ \   _  | | | '_ \|__ |__ \    //
//     ___| | (_) | (_) >   | | | | | |_) | | |_| | | |_) / __/ __/    //
//    |_____|\___/ \___/_/|_|_|_| |_| .__/  |____/|_|_.__/\___\___|    //
//                                   \___|                             //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract Mirror is ERC721Creator {
    constructor() ERC721Creator("Alyse Through the Looking Glass", "Mirror") {}
}
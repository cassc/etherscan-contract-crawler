// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: joogtober
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//          _                __       __              //
//         (_)__  ___  ___ _/ /____  / /  ___ ____    //
//        / / _ \/ _ \/ _ `/ __/ _ \/ _ \/ -_) __/    //
//     __/ /\___/\___/\_, /\__/\___/_.__/\__/_/       //
//    |___/          /___/                            //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract joog is ERC721Creator {
    constructor() ERC721Creator("joogtober", "joog") {}
}
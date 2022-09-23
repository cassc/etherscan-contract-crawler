// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rustdawg’s Masterworks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//        ____             __      __                        //
//       / __ \__  _______/ /_____/ /___ __      ______ _    //
//      / /_/ / / / / ___/ __/ __  / __ `/ | /| / / __ `/    //
//     / _, _/ /_/ (__  ) /_/ /_/ / /_/ /| |/ |/ / /_/ /     //
//    /_/ |_|\__,_/____/\__/\__,_/\__,_/ |__/|__/\__, /      //
//                                              /____/       //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract RDG is ERC721Creator {
    constructor() ERC721Creator(unicode"Rustdawg’s Masterworks", "RDG") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Déjà vu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//       ___   __   _ __                  //
//      / _ \_/_/  (_)\_\_  _  ____ __    //
//     / // / -_) / / _ `/ | |/ / // /    //
//    /____/\__/_/ /\_,_/  |___/\_,_/     //
//            |___/                       //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract Du is ERC721Creator {
    constructor() ERC721Creator(unicode"Déjà vu", "Du") {}
}
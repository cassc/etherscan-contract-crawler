// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Origin Story
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//      __ ____ __ ___ __ __ _    ____ ____ __ ____ _  _     //
//     /  (  _ (  ) __|  |  ( \  / ___|_  _)  (  _ ( \/ )    //
//    (  O )   /)( (_ \)(/    /  \___ \ )((  O )   /)  /     //
//     \__(__\_|__)___(__)_)__)  (____/(__)\__(__\_|__/      //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract OS is ERC721Creator {
    constructor() ERC721Creator("Origin Story", "OS") {}
}
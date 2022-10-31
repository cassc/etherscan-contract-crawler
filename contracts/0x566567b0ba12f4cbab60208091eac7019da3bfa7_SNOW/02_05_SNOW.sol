// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nagano Sunsets
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//     _ __                           ()                              //
//    ' )  )                          /\                    _/_       //
//     /  / __.  _,  __.  ____  __   /  )  . . ____  _   _  /  _      //
//    /  (_(_/|_(_)_(_/|_/ / <_(_)  /__/__(_/_/ / <_/_)_</_<__/_)_    //
//               /|                                                   //
//              |/                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract SNOW is ERC721Creator {
    constructor() ERC721Creator("Nagano Sunsets", "SNOW") {}
}
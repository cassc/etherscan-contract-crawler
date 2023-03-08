// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MoonOwls
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    mmmmm          mmmm   mmmmmmm mmmmmm  mmmm          mmmm    //
//    mmm  m       m  mmm   m     m m    m  mmm  m        mmm     //
//    mmm    m   m    mmm   m     m m    m  mmm    m      mmm     //
//    mmm     m       mmm   m     m m    m  mmm      m    mmm     //
//    mmm             mmm   m     m m    m  mmm        m  mmm     //
//    mmm             mmm   m     m m    m  mmm          m mm     //
//    mmm             mmm   m     m m    m  mmm                   //
//    mmm             mmm   mmmmmmm mmmmmm  mmm                   //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract MOW is ERC721Creator {
    constructor() ERC721Creator("MoonOwls", "MOW") {}
}
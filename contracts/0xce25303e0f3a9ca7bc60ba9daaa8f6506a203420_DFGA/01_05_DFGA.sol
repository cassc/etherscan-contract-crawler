// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dave Frog Animations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    __               ___                //
//     ) ) _      _     )_  _ _   _       //
//    /_/ (_( \) )_)   (   ) (_) (_(      //
//              (_                 _)     //
//                                        //
//                                        //
////////////////////////////////////////////


contract DFGA is ERC721Creator {
    constructor() ERC721Creator("Dave Frog Animations", "DFGA") {}
}
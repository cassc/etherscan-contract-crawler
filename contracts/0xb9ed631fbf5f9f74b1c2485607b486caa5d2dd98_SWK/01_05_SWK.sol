// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Swalk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     ____,_   _, ____,__,  __, ,    //
//    (-(__(-|  | (-/_|(-|  ( |_/     //
//     ____)_|/\|,_/  |,_|__,_| \,    //
//    (    (     (     (    (         //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract SWK is ERC721Creator {
    constructor() ERC721Creator("Swalk", "SWK") {}
}
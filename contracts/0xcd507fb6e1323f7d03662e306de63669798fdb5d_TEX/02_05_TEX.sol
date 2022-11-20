// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TexTrnr
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     ___  ___     ___  __        __       //
//      |  |__  \_/  |  |__) |\ | |__)      //
//      |  |___ / \  |  |  \ | \| |  \      //
//                                          //
//    __________________________________    //
//                                          //
//    * MANIFOLD SMART CONTRACT             //
//    * ERC721                              //
//    * TEXTRNR / TEX                       //
//    __________________________________    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract TEX is ERC721Creator {
    constructor() ERC721Creator("TexTrnr", "TEX") {}
}
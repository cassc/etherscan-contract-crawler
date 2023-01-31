// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Zoop
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//     __, __, _ ___ _  _, _, _  _,   __, , _   ___,  _,  _, __,    //
//     |_  | \ |  |  | / \ |\ | (_    |_) \ |   ` /  / \ / \ |_)    //
//     |   |_/ |  |  | \ / | \| , )   |_)  \|    /   \ / \ / |      //
//     ~~~ ~   ~  ~  ~  ~  ~  ~  ~    ~     )   ~~~   ~   ~  ~      //
//                                         ~'                       //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract EBZP is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Zoop", "EBZP") {}
}
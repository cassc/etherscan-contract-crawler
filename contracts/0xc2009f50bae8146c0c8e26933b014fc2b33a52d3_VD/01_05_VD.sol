// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Valentine's Day
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                       //
//    Digital art about love can take many forms, from abstract images to more literal representations. It can be used to express a range of emotions, from joy and happiness to sadness and longing. Digital art about love can also be used to create a visual representation of a relationship or the feelings associated with it.    //
//                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VD is ERC721Creator {
    constructor() ERC721Creator("Valentine's Day", "VD") {}
}
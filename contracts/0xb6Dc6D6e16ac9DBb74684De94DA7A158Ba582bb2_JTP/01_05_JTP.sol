// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Joey The Photographer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                         //
//     The body of work that this contract pertains to is a series of 1/1 images created by Joey the Photographer. All photographs on this contract were created in the last 5 years during Joey's battle with substance abuse and mental illness. The pieces are heavily inspired by the works of Edward Hopper and his use of color and composition.     //
//                                                                                                                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JTP is ERC721Creator {
    constructor() ERC721Creator("Joey The Photographer", "JTP") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COLOR-DEX BY H.M
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    You might see it , you might not .    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CDX is ERC721Creator {
    constructor() ERC721Creator("COLOR-DEX BY H.M", "CDX") {}
}
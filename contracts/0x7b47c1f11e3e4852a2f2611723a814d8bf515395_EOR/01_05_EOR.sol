// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 𝓔𝓶𝓫𝓻𝓪𝓬𝓮 𝓸𝓯 𝓡𝓮𝓪𝓵𝓲𝓽𝔂
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    𝓐𝓝𝓝𝓐𝓑𝓐𝓨𝓛 𝓔𝓓𝓘𝓣𝓘𝓞𝓝𝓢    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract EOR is ERC721Creator {
    constructor() ERC721Creator(unicode"𝓔𝓶𝓫𝓻𝓪𝓬𝓮 𝓸𝓯 𝓡𝓮𝓪𝓵𝓲𝓽𝔂", "EOR") {}
}
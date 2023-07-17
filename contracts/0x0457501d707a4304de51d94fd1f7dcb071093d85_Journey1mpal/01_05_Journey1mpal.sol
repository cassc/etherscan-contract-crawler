// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1mpal's Journey
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    The first NFT to celebrate 1mpal's 30 days of continuous threads.                              //
//                                                                                                   //
//    This is an AI-generated illustration.                                                          //
//                                                                                                   //
//    It was created for those who have been following 1mpal's journey.                              //
//                                                                                                   //
//    𝓝𝓸 𝓾𝓽𝓲𝓵𝓲𝓽𝔂, 𝓝𝓸 𝓶𝓮𝓶𝓫𝓮𝓻𝓼𝓱𝓲𝓹, 𝓑𝓾𝓽 𝓹𝓻𝓸𝓫𝓪𝓫𝓵𝔂 𝓼𝓸𝓶𝓮𝓽𝓱𝓲𝓷𝓰.    //
//                                                                                                   //
//    👉️ https://twitter.com/impalementd                                                            //
//    👉️ link3.to/impalementd                                                                       //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract Journey1mpal is ERC1155Creator {
    constructor() ERC1155Creator("1mpal's Journey", "Journey1mpal") {}
}
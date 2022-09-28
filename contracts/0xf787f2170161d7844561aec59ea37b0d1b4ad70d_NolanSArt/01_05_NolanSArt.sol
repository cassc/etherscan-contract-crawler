// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nolan Solomon Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    🎨Nolan Solomon NFT Art🖌️🚀    //
//                                    //
//                                    //
////////////////////////////////////////


contract NolanSArt is ERC721Creator {
    constructor() ERC721Creator("Nolan Solomon Art", "NolanSArt") {}
}
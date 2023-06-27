// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moving Pictures
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    🅜🅞🅥🅘🅝🅖 🅟🅘🅒🅣🅤🅡🅔🅢    //
//                                     //
//                                     //
/////////////////////////////////////////


contract MP4NFT is ERC721Creator {
    constructor() ERC721Creator("Moving Pictures", "MP4NFT") {}
}
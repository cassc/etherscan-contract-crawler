// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rixou - AI x Cyberpunk Pop Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    AI x Cyberpunk Pop Art is a unique collection of 100 cartoons that is inspired by          //
//    elements from cyberpunk-era culture, such as Japanese anime and manga, American            //
//    1980s popular culture. It's been created by a multidisciplinary designer and developer     //
//    using AI technology and other creative tools. All artworks will come with a                //
//    300dpi version for you to use for print on any support.                                    //
//                                                                                               //
//    Website: https://rixou.io //// Twitter: rixou_io //// Instagram: Rixou IO                  //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract rixouaixcyberpunkpopart is ERC721Creator {
    constructor() ERC721Creator("Rixou - AI x Cyberpunk Pop Art", "rixouaixcyberpunkpopart") {}
}
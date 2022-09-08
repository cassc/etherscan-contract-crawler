// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inspirations by zv3r
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
//           ,----,            __  ,-.     //
//         .'   .`|     .---.,' ,'/ /|     //
//      .'   .'  .'   /.  ./|'  | |' |     //
//    ,---, '   ./  .-' . ' ||  |   ,'     //
//    ;   | .'  /  /___/ \: |'  :  /       //
//    `---' /  ;--,.   \  ' .|  | '        //
//      /  /  / .`| \   \   ';  : |        //
//    ./__;     .'   \   \   |  , ;        //
//    ;   |  .'       \   \ | ---'         //
//    `---'            '---"               //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract zvr is ERC721Creator {
    constructor() ERC721Creator("Inspirations by zv3r", "zvr") {}
}
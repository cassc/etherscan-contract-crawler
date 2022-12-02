// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Split
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//     .oooooo..o ooooooooo.   ooooo        ooooo ooooooooooooo     //
//    d8P'    `Y8 `888   `Y88. `888'        `888' 8'   888   `8     //
//    Y88bo.       888   .d88'  888          888       888          //
//     `"Y8888o.   888ooo88P'   888          888       888          //
//         `"Y88b  888          888          888       888          //
//    oo     .d8P  888          888       o  888       888          //
//    8""88888P'  o888o        o888ooooood8 o888o     o888o         //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract SPLIT is ERC721Creator {
    constructor() ERC721Creator("Split", "SPLIT") {}
}
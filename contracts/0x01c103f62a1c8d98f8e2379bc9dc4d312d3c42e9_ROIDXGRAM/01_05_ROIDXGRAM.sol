// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Polaroid Studies : The Photogram Experience
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//    𝖳𝗁𝗂𝗌 𝗂𝗌 𝖺 𝖯𝗈𝗅𝖺𝗋𝗈𝗂𝖽 𝖯𝗁𝗈𝗍𝗈𝗀𝗋𝖺𝗆 𝖻𝗒 𝖳𝗁𝗂𝖾𝗋𝗋𝗋𝗋𝗋𝗋𝗋𝗋𝗋𝗒    //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract ROIDXGRAM is ERC721Creator {
    constructor() ERC721Creator("Polaroid Studies : The Photogram Experience", "ROIDXGRAM") {}
}
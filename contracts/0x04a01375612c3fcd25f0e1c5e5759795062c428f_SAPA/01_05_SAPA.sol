// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scrawlzy Art Physicals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//                                           //
//      _____    _____   _____    _____      //
//     (_____)  (_____) (_____)  (_____)     //
//    (_)___   (_)___(_)(_)__(_)(_)___(_)    //
//      (___)_ (_______)(_____) (_______)    //
//      ____(_)(_)   (_)(_)     (_)   (_)    //
//     (_____) (_)   (_)(_)     (_)   (_)    //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract SAPA is ERC721Creator {
    constructor() ERC721Creator("Scrawlzy Art Physicals", "SAPA") {}
}
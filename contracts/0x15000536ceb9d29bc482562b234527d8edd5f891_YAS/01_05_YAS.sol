// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yasmeen Suleiman - Open Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//    ___       ___       __  ___  __   ___           __         ___  ___          //
//     |  |__| |__   /\  |__)  |  /  \ |__  \ /  /\  /__`  |\/| |__  |__  |\ |     //
//     |  |  | |___ /~~\ |  \  |  \__/ |     |  /~~\ .__/  |  | |___ |___ | \|     //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract YAS is ERC721Creator {
    constructor() ERC721Creator("Yasmeen Suleiman - Open Editions", "YAS") {}
}
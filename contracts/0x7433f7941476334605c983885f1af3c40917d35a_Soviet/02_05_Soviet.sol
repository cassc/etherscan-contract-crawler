// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soviet
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ─▄▀▐▌▀▄─                    //
//    ▐──▐▌──▌                    //
//    ▐─▄██▄─▌                    //
//    ▐█▀▐▌▀█▌                    //
//    ─▀▄▐▌▄▀─                    //
//                                //
//    .                           //
//    ███▄─████─▄██▄─▄██▄─████    //
//    █──█─█▄▄──█▄▄█─█──▀─█▄▄─    //
//    ███▀─█▀▀──█▀▀█─█──▄─█▀▀─    //
//    █────████─█──█─▀██▀─████    //
//                                //
//                                //
////////////////////////////////////


contract Soviet is ERC721Creator {
    constructor() ERC721Creator("Soviet", "Soviet") {}
}
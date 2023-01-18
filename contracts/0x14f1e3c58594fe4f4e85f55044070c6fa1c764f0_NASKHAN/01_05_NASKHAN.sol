// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BITCOIN ART - LIMITED EDITION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//    .-. .-.  .--.   .----..-. .-..-. .-.  .--.  .-. .-.    //
//    |  `| | / {} \ { {__  | |/ / | {_} | / {} \ |  `| |    //
//    | |\  |/  /\  \.-._} }| |\ \ | { } |/  /\  \| |\  |    //
//    `-' `-'`-'  `-'`----' `-' `-'`-' `-'`-'  `-'`-' `-'    //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract NASKHAN is ERC721Creator {
    constructor() ERC721Creator("BITCOIN ART - LIMITED EDITION", "NASKHAN") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIRAI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     __  __  ____  ____    __    ____     //
//    (  \/  )(_  _)(  _ \  /__\  (_  _)    //
//     )    (  _)(_  )   / /(__)\  _)(_     //
//    (_/\/\_)(____)(_)\_)(__)(__)(____)    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract MIRAI is ERC721Creator {
    constructor() ERC721Creator("MIRAI", "MIRAI") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Your Leader
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//     _____ _____  ______  ___   _   _     //
//    |  _  |  __ \ |  _  \/ _ \ | \ | |    //
//    | | | | |  \/ | | | / /_\ \|  \| |    //
//    | | | | | __  | | | |  _  || . ` |    //
//    \ \_/ / |_\ \ | |/ /| | | || |\  |    //
//     \___/ \____/ |___/ \_| |_/\_| \_/    //
//                                          //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract LEAD is ERC721Creator {
    constructor() ERC721Creator("Your Leader", "LEAD") {}
}
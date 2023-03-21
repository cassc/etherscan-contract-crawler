// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Third Eyes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    𝙿𝚑𝚘𝚝𝚘𝚐𝚛𝚊𝚙𝚑𝚢 𝙱𝚢 𝚂/𝚃    //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TdEs is ERC721Creator {
    constructor() ERC721Creator("Third Eyes", "TdEs") {}
}
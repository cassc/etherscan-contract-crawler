// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AIthereals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//       _________________________    //
//      /  _  \__    ___/   _____/    //
//     /  /_\  \|    |  \_____  \     //
//    /    |    \    |  /        \    //
//    \____|__  /____| /_______  /    //
//            \/               \/     //
//                                    //
//                                    //
////////////////////////////////////////


contract ATS is ERC721Creator {
    constructor() ERC721Creator("AIthereals", "ATS") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: QWER
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//    ________  ___________    //
//    \_____  \ \_   _____/    //
//     /  / \  \ |    __)_     //
//    /   \_/.  \|        \    //
//    \_____\ \_/_______  /    //
//           \__>       \/     //
//                             //
//                             //
//                             //
/////////////////////////////////


contract QE is ERC721Creator {
    constructor() ERC721Creator("QWER", "QE") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: esscentrix
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//       ^       //
//      / \      //
//     /   \     //
//    /     \    //
//    |  |  |    //
//    |  |  |    //
//    \  \  /    //
//     \  \/     //
//     /\  \     //
//    /  \  \    //
//    |  |  |    //
//    |  |  |    //
//    \     /    //
//     \   /     //
//      \ /      //
//       v       //
//               //
//               //
///////////////////


contract ess is ERC721Creator {
    constructor() ERC721Creator("esscentrix", "ess") {}
}
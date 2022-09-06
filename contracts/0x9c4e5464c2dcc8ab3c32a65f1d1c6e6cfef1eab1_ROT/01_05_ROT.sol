// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Ruins of Tomorrow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    |~\   /~\    /|\   |   |   |~\  |\    |   |       //
//    |  \ /   \  / | \  | \ |   |  \ | \   | \ |       //
//    |  / \   / /  |  \ |  \|   |  / |  \  |  \|       //
//    |_/   \ /     |    |   |\  |_/  |   | |   |\      //
//    | \   / \     |    |   | \ | \  |   | |   | \     //
//    |  \ /   \    |    |   |   |  \ |   | |   |       //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract ROT is ERC721Creator {
    constructor() ERC721Creator("The Ruins of Tomorrow", "ROT") {}
}
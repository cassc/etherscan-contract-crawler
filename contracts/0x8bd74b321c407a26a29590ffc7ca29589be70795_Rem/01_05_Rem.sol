// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rosez
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    |~\  /~\  / |\    /|\    /|~~-__|\    /| /       //
//    |  \/   \/  | \  / | \  / |     | \  / |/        //
//    |  /\   /___|  \/  |  \/  |_____|  \/  /____     //
//    |_/  \ /    /      |      |  |  |      |   /     //
//    | \  / \   /|      |      |  |  |      |  /      //
//    |  \/   \ / |      |      |  |  |      | /       //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Rem is ERC721Creator {
    constructor() ERC721Creator("Rosez", "Rem") {}
}
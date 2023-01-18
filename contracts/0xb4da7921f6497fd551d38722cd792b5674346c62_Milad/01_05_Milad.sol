// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: milad moghadam
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      __  __     ___     _            _        ____      //
//     |  \/  |   |_ _|   | |          / \      |  _ \     //
//     | |\/| |    | |    | |         / _ \     | | | |    //
//     | |  | |    | |    | |___     / ___ \    | |_| |    //
//     |_|  |_|   |___|   |_____|   /_/   \_\   |____/     //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract Milad is ERC721Creator {
    constructor() ERC721Creator("milad moghadam", "Milad") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Juice x Joe Mediums
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//      __  __          _ _                         //
//     |  \/  | ___  __| (_)_   _ _ __ ___  ___     //
//     | |\/| |/ _ \/ _` | | | | | '_ ` _ \/ __|    //
//     | |  | |  __/ (_| | | |_| | | | | | \__ \    //
//     |_|  |_|\___|\__,_|_|\__,_|_| |_| |_|___/    //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract JXJMED is ERC721Creator {
    constructor() ERC721Creator("Juice x Joe Mediums", "JXJMED") {}
}
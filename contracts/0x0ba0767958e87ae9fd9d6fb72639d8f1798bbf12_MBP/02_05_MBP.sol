// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Photographs Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//        __  ____      __               __   ____     //
//       /  |/  (_)____/ /_  ____ ____  / /  / __ )    //
//      / /|_/ / / ___/ __ \/ __ `/ _ \/ /  / __  |    //
//     / /  / / / /__/ / / / /_/ /  __/ /  / /_/ /     //
//    /_/  /_/_/\___/_/ /_/\__,_/\___/_/  /_____/      //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract MBP is ERC721Creator {
    constructor() ERC721Creator("Photographs Collection", "MBP") {}
}
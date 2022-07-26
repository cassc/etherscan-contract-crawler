// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mersona Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//        __  ___                                    //
//       /  |/  /__  ______________  ____  ____ _    //
//      / /|_/ / _ \/ ___/ ___/ __ \/ __ \/ __ `/    //
//     / /  / /  __/ /  (__  ) /_/ / / / / /_/ /     //
//    /_/  /_/\___/_/  /____/\____/_/ /_/\__,_/      //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract MRSN is ERC721Creator {
    constructor() ERC721Creator("Mersona Collection", "MRSN") {}
}
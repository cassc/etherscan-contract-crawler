// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: no-verse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//       ____  ____       _   _____  _____________     //
//      / __ \/ __ \_____| | / / _ \/ ___/ ___/ _ \    //
//     / / / / /_/ /_____/ |/ /  __/ /  (__  )  __/    //
//    /_/ /_/\____/      |___/\___/_/  /____/\___/     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract NVS is ERC721Creator {
    constructor() ERC721Creator("no-verse", "NVS") {}
}
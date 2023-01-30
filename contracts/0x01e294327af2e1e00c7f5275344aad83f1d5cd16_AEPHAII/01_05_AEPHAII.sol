// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOPE DIGGERS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//       _____  _____________________  ___ ___    _____  .___     //
//      /  _  \ \_   _____/\______   \/   |   \  /  _  \ |   |    //
//     /  /_\  \ |    __)_  |     ___/    ~    \/  /_\  \|   |    //
//    /    |    \|        \ |    |   \    Y    /    |    \   |    //
//    \____|__  /_______  / |____|    \___|_  /\____|__  /___|    //
//            \/        \/                  \/         \/         //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract AEPHAII is ERC721Creator {
    constructor() ERC721Creator("HOPE DIGGERS", "AEPHAII") {}
}
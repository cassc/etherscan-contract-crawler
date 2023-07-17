// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABCD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//       _____ ___________________ ________       //
//      /  _  \\______   \_   ___ \\______ \      //
//     /  /_\  \|    |  _/    \  \/ |    |  \     //
//    /    |    \    |   \     \____|    `   \    //
//    \____|__  /______  /\______  /_______  /    //
//            \/       \/        \/        \/     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ABCD is ERC721Creator {
    constructor() ERC721Creator("ABCD", "ABCD") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Certificación Credilikeme
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//                                                                 //
//                             _ _ _ _ _                           //
//       ___ _ __ ___  ___  __| (_) (_) | _____ _ __ ___   ___     //
//      / __| '__/ _ \/ _ \/ _` | | | | |/ / _ \ '_ ` _ \ / _ \    //
//     | (__| | |  __/  __/ (_| | | | |   <  __/ | | | | |  __/    //
//      \___|_|  \___|\___|\__,_|_|_|_|_|\_\___|_| |_| |_|\___|    //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract credi is ERC721Creator {
    constructor() ERC721Creator(unicode"Certificación Credilikeme", "credi") {}
}
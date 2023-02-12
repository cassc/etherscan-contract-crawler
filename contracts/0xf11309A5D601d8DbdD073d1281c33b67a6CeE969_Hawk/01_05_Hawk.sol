// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Quiet Reflection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//         __ __               __    _____ __         _         //
//        / // /___ _ _    __ / /__ / ___// /  ___ _ (_)___     //
//       / _  // _ `/| |/|/ //  '_// /__ / _ \/ _ `// // _ \    //
//      /_//_/ \_,_/ |__,__//_/\_\ \___//_//_/\_,_//_//_//_/    //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract Hawk is ERC721Creator {
    constructor() ERC721Creator("Quiet Reflection", "Hawk") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HUGO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//       ___ ___   __ __  __ __  _____  _____     //
//      /  //  /  /  |  \/  |  \/   __\/  _  \    //
//     /  //  /   |  _  ||  |  ||  |_ ||  |  |    //
//    /__//__/    \__|__/\_____/\_____/\_____/    //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract HGO is ERC721Creator {
    constructor() ERC721Creator("HUGO", "HGO") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deborah Berry Fine Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//       _____               ____     ____      __   __     //
//     |_ " _|     ___    U|  _"\ u / __"| u   \ \ / /      //
//       | |      |_"_|   \| |_) |/<\___ \/     \ V /       //
//      /| |\      | |     |  __/   u___) |    U_|"|_u      //
//     u |_|U    U/| |\u   |_|      |____/>>     |_|        //
//     _// \\_.-,_|___|_,-.||>>_     )(  (__).-,//|(_       //
//    (__) (__)\_)-' '-(_/(__)__)   (__)      \_) (__)      //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract DBP is ERC721Creator {
    constructor() ERC721Creator("Deborah Berry Fine Art", "DBP") {}
}
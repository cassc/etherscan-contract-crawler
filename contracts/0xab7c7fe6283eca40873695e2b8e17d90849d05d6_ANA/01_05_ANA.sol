// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moon Rose.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//               _   _              //
//         /\   | \ | |   /\        //
//        /  \  |  \| |  /  \       //
//       / /\ \ | . ` | / /\ \      //
//      / ____ \| |\  |/ ____ \     //
//     /_/    \_\_| \_/_/    \_\    //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract ANA is ERC721Creator {
    constructor() ERC721Creator("Moon Rose.", "ANA") {}
}
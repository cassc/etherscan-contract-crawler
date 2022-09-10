// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: saraboychuk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//              /\                     //
//             /**\                    //
//            /****\   /\              //
//           /      \ /**\             //
//          /  /\    /    \            //
//         /  /  \  /      \           //
//        /  /    \/ /\     \          //
//       /  /      \/  \/\   \         //
//      /__/_______/___/__\___\        //
//                                     //
//                                     //
/////////////////////////////////////////


contract sb is ERC721Creator {
    constructor() ERC721Creator("saraboychuk", "sb") {}
}
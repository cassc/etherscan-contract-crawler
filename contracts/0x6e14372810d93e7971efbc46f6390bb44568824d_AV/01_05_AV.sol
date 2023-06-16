// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AnnaV
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//          __      __    //
//         /\ \    / /    //
//        /  \ \  / /     //
//       / /\ \ \/ /      //
//      / ____ \  /       //
//     /_/    \_\/        //
//                        //
//                        //
//                        //
//                        //
//                        //
////////////////////////////


contract AV is ERC721Creator {
    constructor() ERC721Creator("AnnaV", "AV") {}
}
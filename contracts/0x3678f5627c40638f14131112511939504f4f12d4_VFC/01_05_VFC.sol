// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: V's First Contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//      __    __      //
//      ) )  ( (      //
//     ( (    ) )     //
//      \ \  / /      //
//       \ \/ /       //
//        \  /        //
//         \/         //
//                    //
//                    //
//                    //
//                    //
////////////////////////


contract VFC is ERC721Creator {
    constructor() ERC721Creator("V's First Contract", "VFC") {}
}
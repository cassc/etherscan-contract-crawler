// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YCN IV
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     __     _______ _   _   _______      __    //
//     \ \   / / ____| \ | | |_   _\ \    / /    //
//      \ \_/ / |    |  \| |   | |  \ \  / /     //
//       \   /| |    | . ` |   | |   \ \/ /      //
//        | | | |____| |\  |  _| |_   \  /       //
//        |_|  \_____|_| \_| |_____|   \/        //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract YCNIV is ERC721Creator {
    constructor() ERC721Creator("YCN IV", "YCNIV") {}
}
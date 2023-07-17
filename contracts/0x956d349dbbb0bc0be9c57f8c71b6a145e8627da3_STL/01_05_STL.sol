// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STILL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//       _________________    __     //
//      / ___/_  __/  _/ /   / /     //
//      \__ \ / /  / // /   / /      //
//     ___/ // / _/ // /___/ /___    //
//    /____//_/ /___/_____/_____/    //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract STL is ERC721Creator {
    constructor() ERC721Creator("STILL", "STL") {}
}
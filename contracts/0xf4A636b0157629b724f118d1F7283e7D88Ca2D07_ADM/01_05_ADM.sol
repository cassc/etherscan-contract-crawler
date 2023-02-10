// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aster Da Master
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//      ^    ^    ^    ^    ^         //
//     /A\  /s\  /t\  /e\  /r\        //
//    <___><___><___><___><___>       //
//                                    //
//                                    //
////////////////////////////////////////


contract ADM is ERC1155Creator {
    constructor() ERC1155Creator("Aster Da Master", "ADM") {}
}
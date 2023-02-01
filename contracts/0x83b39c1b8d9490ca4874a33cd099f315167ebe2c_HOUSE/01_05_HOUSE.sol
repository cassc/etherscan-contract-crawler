// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MATE HOUSE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    　 ／l、        //
//    ﾞ（ﾟ､ ｡ ７     //
//    　l、ﾞ ~ヽ      //
//    　じしf_, )ノ    //
//                 //
//                 //
/////////////////////


contract HOUSE is ERC721Creator {
    constructor() ERC721Creator("MATE HOUSE", "HOUSE") {}
}
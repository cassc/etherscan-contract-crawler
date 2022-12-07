// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everything Tangy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//     ╱|、        //
//    (` - 7      //
//    |、⁻〵        //
//    じしˍ,)ノ      //
//                //
//    TANGY <3    //
//                //
//                //
////////////////////


contract TANGY is ERC721Creator {
    constructor() ERC721Creator("Everything Tangy", "TANGY") {}
}
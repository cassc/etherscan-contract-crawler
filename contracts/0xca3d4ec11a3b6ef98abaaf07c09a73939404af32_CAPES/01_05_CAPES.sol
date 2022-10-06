// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLOUD APES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//              //
//      /~\     //
//     C oo     //
//     _( ^)    //
//    /   ~\    //
//    $CAPES    //
//              //
//              //
//////////////////


contract CAPES is ERC721Creator {
    constructor() ERC721Creator("CLOUD APES", "CAPES") {}
}
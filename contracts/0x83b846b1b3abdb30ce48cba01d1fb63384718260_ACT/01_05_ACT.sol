// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WINEPAPIPRODUCTION
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    ACTLIKEYOUKNOWME_CONTRACT    //
//                                 //
//                                 //
/////////////////////////////////////


contract ACT is ERC721Creator {
    constructor() ERC721Creator("WINEPAPIPRODUCTION", "ACT") {}
}
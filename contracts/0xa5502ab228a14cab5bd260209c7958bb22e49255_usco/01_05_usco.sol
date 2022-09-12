// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: us_co
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//     __ __  ______ ____  ____      //
//    |  |  \/  ___// ___\/  _ \     //
//    |  |  /\___ \\  \__(  <_> )    //
//    |____//____  >\___  >____/     //
//               \/     \/           //
//                                   //
//                                   //
///////////////////////////////////////


contract usco is ERC721Creator {
    constructor() ERC721Creator("us_co", "usco") {}
}
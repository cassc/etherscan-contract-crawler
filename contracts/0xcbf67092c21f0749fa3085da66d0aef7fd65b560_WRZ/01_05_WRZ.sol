// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WeRatZ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    - WeRatz - [email protected] - [email protected] -    //
//                                   //
//             (_)_(_)               //
//              (o o)                //
//             ==\o/==               //
//                                   //
//                                   //
///////////////////////////////////////


contract WRZ is ERC721Creator {
    constructor() ERC721Creator("WeRatZ", "WRZ") {}
}
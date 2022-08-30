// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neo Devann
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    |\ | _  _   |~\ _    _  _  _     //
//    | \|(/_(_)  |_/(/_\/(_|| || |    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract NDN is ERC721Creator {
    constructor() ERC721Creator("Neo Devann", "NDN") {}
}
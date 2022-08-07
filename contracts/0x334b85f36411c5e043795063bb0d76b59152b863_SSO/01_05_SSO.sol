// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The SSO Gallery
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    Inspiration is Everywhere when you Open your Mind.    //
//    - StrawberrySpiced                                    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SSO is ERC721Creator {
    constructor() ERC721Creator("The SSO Gallery", "SSO") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeKunTa Mini Films
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    A new typE of expression is needed here and now!    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract PMF is ERC721Creator {
    constructor() ERC721Creator("PepeKunTa Mini Films", "PMF") {}
}
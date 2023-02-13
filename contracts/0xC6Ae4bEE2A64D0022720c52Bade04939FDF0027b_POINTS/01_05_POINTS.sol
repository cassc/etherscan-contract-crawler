// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POINTS.COM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                  .__        __              //
//    ______   ____ |__| _____/  |_  ______    //
//    \____ \ /  _ \|  |/    \   __\/  ___/    //
//    |  |_> >  <_> )  |   |  \  |  \___ \     //
//    |   __/ \____/|__|___|  /__| /____  >    //
//    |__|                  \/          \/     //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract POINTS is ERC721Creator {
    constructor() ERC721Creator("POINTS.COM", "POINTS") {}
}
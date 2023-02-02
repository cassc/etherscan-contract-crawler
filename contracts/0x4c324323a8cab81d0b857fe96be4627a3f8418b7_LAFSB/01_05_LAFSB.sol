// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amore a prima vista - Banner
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    Amore a prima vista - Banner Edition    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract LAFSB is ERC721Creator {
    constructor() ERC721Creator("Amore a prima vista - Banner", "LAFSB") {}
}
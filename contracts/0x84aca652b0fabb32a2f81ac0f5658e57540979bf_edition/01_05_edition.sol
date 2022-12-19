// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OPEN EDITION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    OPEN EDITION    //
//    by              //
//    OKSANA          //
//    BULGAKOVA       //
//                    //
//                    //
////////////////////////


contract edition is ERC721Creator {
    constructor() ERC721Creator("OPEN EDITION", "edition") {}
}
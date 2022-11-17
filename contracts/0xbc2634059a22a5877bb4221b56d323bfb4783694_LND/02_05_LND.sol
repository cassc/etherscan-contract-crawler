// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Love never dies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//             <-. (`-')_  _(`-')        //
//       <-.      \( OO) )( (OO ).->     //
//     ,--. )  ,--./ ,--/  \    .'_      //
//     |  (`-')|   \ |  |  '`'-..__)     //
//     |  |OO )|  . '|  |) |  |  ' |     //
//    (|  '__ ||  |\    |  |  |  / :     //
//     |     |'|  | \   |  |  '-'  /     //
//     `-----' `--'  `--'  `------'      //
//                                       //
//                                       //
///////////////////////////////////////////


contract LND is ERC721Creator {
    constructor() ERC721Creator("Love never dies", "LND") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Http_errors
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//    |_|_|__|_ _    _  _ _ _  _ _    //
//    | | |  | |_)__(/_| | (_)| _\    //
//             |                      //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract ER is ERC721Creator {
    constructor() ERC721Creator("Http_errors", "ER") {}
}
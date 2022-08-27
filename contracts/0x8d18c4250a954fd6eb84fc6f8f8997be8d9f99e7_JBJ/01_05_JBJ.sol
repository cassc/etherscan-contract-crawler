// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JulbyJuli
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//          _       _ _               _       _ _     //
//         | |_   _| | |__  _   _    | |_   _| (_)    //
//      _  | | | | | | '_ \| | | |_  | | | | | | |    //
//     | |_| | |_| | | |_) | |_| | |_| | |_| | | |    //
//      \___/ \__,_|_|_.__/ \__, |\___/ \__,_|_|_|    //
//                          |___/                     //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract JBJ is ERC721Creator {
    constructor() ERC721Creator("JulbyJuli", "JBJ") {}
}
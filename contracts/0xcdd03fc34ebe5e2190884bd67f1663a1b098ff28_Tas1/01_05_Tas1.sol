// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Taslemat1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//      _______        _____   __     //
//     |__   __|/\    / ____| /_ |    //
//        | |  /  \  | (___    | |    //
//        | | / /\ \  \___ \   | |    //
//        | |/ ____ \ ____) |  | |    //
//        |_/_/    \_\_____/   |_|    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract Tas1 is ERC721Creator {
    constructor() ERC721Creator("Taslemat1", "Tas1") {}
}
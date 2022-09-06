// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: degenerativeburritos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    ___.                       .__  __              //
//    \_ |__  __ ________________|__|/  |_  ____      //
//     | __ \|  |  \_  __ \_  __ \  \   __\/  _ \     //
//     | \_\ \  |  /|  | \/|  | \/  ||  | (  <_> )    //
//     |___  /____/ |__|   |__|  |__||__|  \____/     //
//         \/                                         //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract dbr is ERC721Creator {
    constructor() ERC721Creator("degenerativeburritos", "dbr") {}
}
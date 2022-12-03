// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Shape of Dreams
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//            _                          _  _     //
//     _ __  (_) _   _  _ __ ___    ___ | |(_)    //
//    | '_ \ | || | | || '_ ` _ \  / _ \| || |    //
//    | |_) || || |_| || | | | | ||  __/| || |    //
//    | .__/ |_| \__,_||_| |_| |_| \___||_||_|    //
//    |_|                                         //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract DREAMS is ERC1155Creator {
    constructor() ERC1155Creator("The Shape of Dreams", "DREAMS") {}
}
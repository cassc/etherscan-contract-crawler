// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ladosa
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    .____                .___                        //
//    |    |   _____     __| _/____  ___________       //
//    |    |   \__  \   / __ |/  _ \/  ___/\__  \      //
//    |    |___ / __ \_/ /_/ (  <_> )___ \  / __ \_    //
//    |_______ (____  /\____ |\____/____  >(____  /    //
//            \/    \/      \/          \/      \/     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Ladosa is ERC1155Creator {
    constructor() ERC1155Creator("Ladosa", "Ladosa") {}
}
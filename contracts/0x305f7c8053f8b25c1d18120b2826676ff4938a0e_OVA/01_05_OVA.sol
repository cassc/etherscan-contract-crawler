// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ME vs ME by OVACHINSKY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//      __  __ ______         __  __ ______     //
//     |  \/  |  ____|       |  \/  |  ____|    //
//     | \  / | |____   _____| \  / | |__       //
//     | |\/| |  __\ \ / / __| |\/| |  __|      //
//     | |  | | |___\ V /\__ \ |  | | |____     //
//     |_|  |_|______\_/ |___/_|  |_|______|    //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract OVA is ERC721Creator {
    constructor() ERC721Creator("ME vs ME by OVACHINSKY", "OVA") {}
}
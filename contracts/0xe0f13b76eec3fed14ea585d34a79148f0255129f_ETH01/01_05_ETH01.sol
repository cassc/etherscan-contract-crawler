// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ethereum Genesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//       _____                                                 //
//      /  _  \__  _  __ ____   __________   _____   ____      //
//     /  /_\  \ \/ \/ // __ \ /  ___/  _ \ /     \_/ __ \     //
//    /    |    \     /\  ___/ \___ (  <_> )  Y Y  \  ___/     //
//    \____|__  /\/\_/  \___  >____  >____/|__|_|  /\___  >    //
//            \/            \/     \/            \/     \/     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract ETH01 is ERC721Creator {
    constructor() ERC721Creator("Ethereum Genesis", "ETH01") {}
}
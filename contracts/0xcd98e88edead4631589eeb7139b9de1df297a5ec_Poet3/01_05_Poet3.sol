// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Poet3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    __________              __ ________      //
//    \______   \____   _____/  |\_____  \     //
//     |     ___/  _ \_/ __ \   __\_(__  <     //
//     |    |  (  <_> )  ___/|  | /       \    //
//     |____|   \____/ \___  >__|/______  /    //
//                         \/           \/     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract Poet3 is ERC1155Creator {
    constructor() ERC1155Creator("Poet3", "Poet3") {}
}
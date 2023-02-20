// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The [G]ood [M]ourning Faders
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     .---.  .---. .-.   .-..----.    //
//    {_   _}/   __}|  `.'  || {_      //
//      | |  \  {_ }| |\ /| || |       //
//      `-'   `---' `-' ` `-'`-'       //
//                                     //
//                                     //
/////////////////////////////////////////


contract tGMf is ERC1155Creator {
    constructor() ERC1155Creator("The [G]ood [M]ourning Faders", "tGMf") {}
}
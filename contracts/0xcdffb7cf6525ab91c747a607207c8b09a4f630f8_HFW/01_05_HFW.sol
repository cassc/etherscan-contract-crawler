// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Have Read Far And Wide
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     ██░ ██   █████▒█     █░    //
//    ▓██░ ██▒▓██   ▒▓█░ █ ░█░    //
//    ▒██▀▀██░▒████ ░▒█░ █ ░█     //
//    ░▓█ ░██ ░▓█▒  ░░█░ █ ░█     //
//    ░▓█▒░██▓░▒█░   ░░██▒██▓     //
//     ▒ ░░▒░▒ ▒ ░   ░ ▓░▒ ▒      //
//     ▒ ░▒░ ░ ░       ▒ ░ ░      //
//     ░  ░░ ░ ░ ░     ░   ░      //
//     ░  ░  ░           ░        //
//                                //
//                                //
//                                //
////////////////////////////////////


contract HFW is ERC721Creator {
    constructor() ERC721Creator("I Have Read Far And Wide", "HFW") {}
}
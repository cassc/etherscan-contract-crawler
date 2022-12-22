// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Templeas of Japan Airdrop
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    One last drop    //
//                     //
//                     //
/////////////////////////


contract JAPAN is ERC1155Creator {
    constructor() ERC1155Creator("Templeas of Japan Airdrop", "JAPAN") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STATEMENTS by DBx
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    𝐬𝐚𝐲 𝐬𝐨𝐦𝐞𝐭𝐡𝐢𝐧𝐠    //
//                                 //
//                                 //
/////////////////////////////////////


contract STMNT is ERC721Creator {
    constructor() ERC721Creator("STATEMENTS by DBx", "STMNT") {}
}
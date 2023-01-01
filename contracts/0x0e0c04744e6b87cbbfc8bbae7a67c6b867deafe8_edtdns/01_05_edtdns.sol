// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dns_err
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    "error server not responding"    //
//                                     //
//                                     //
/////////////////////////////////////////


contract edtdns is ERC1155Creator {
    constructor() ERC1155Creator("dns_err", "edtdns") {}
}
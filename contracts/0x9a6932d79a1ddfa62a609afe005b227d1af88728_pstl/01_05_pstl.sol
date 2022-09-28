// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pstl.gif
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//    bWFkZSBoYXN0aWx5IHdoaWxlIGZhbGxpbmcgYXNsZWVwIGFuZCBhbmdyeSBhdCB0aGUgd29ybGQKCnBhc3RlbA    //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract pstl is ERC721Creator {
    constructor() ERC721Creator("pstl.gif", "pstl") {}
}
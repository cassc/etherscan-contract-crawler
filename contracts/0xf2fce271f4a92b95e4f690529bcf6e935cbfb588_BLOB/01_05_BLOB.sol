// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BlobBoi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//     ____  __    _____  ____  ____  _____  ____     //
//    (  _ \(  )  (  _  )(  _ \(  _ \(  _  )(_  _)    //
//     ) _ < )(__  )(_)(  ) _ < ) _ < )(_)(  _)(_     //
//    (____/(____)(_____)(____/(____/(_____)(____)    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract BLOB is ERC1155Creator {
    constructor() ERC1155Creator("BlobBoi", "BLOB") {}
}
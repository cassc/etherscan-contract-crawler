// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Follow the ReMeme
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//     ____  __   __    __     __   _  _    ____  _  _  ____    ____  ____  _  _  ____  _  _  ____     //
//    (  __)/  \ (  )  (  )   /  \ / )( \  (_  _)/ )( \(  __)  (  _ \(  __)( \/ )(  __)( \/ )(  __)    //
//     ) _)(  O )/ (_/\/ (_/\(  O )\ /\ /    )(  ) __ ( ) _)    )   / ) _) / \/ \ ) _) / \/ \ ) _)     //
//    (__)  \__/ \____/\____/ \__/ (_/\_)   (__) \_)(_/(____)  (__\_)(____)\_)(_/(____)\_)(_/(____)    //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FTR is ERC1155Creator {
    constructor() ERC1155Creator("Follow the ReMeme", "FTR") {}
}
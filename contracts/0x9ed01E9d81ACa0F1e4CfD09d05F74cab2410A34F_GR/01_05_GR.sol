// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gorfy ReMemer
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//      ___   __  ____  ____  _  _    ____  ____  _  _  ____  _  _  ____  ____     //
//     / __) /  \(  _ \(  __)( \/ )  (  _ \(  __)( \/ )(  __)( \/ )(  __)(  _ \    //
//    ( (_ \(  O ))   / ) _)  )  /    )   / ) _) / \/ \ ) _) / \/ \ ) _)  )   /    //
//     \___/ \__/(__\_)(__)  (__/    (__\_)(____)\_)(_/(____)\_)(_/(____)(__\_)    //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract GR is ERC1155Creator {
    constructor() ERC1155Creator("Gorfy ReMemer", "GR") {}
}
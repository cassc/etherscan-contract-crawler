// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kool Kiwi Project
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//     _   __            _   _   ___          _         //
//    | | / /           | | | | / (_)        (_)        //
//    | |/ /  ___   ___ | | | |/ / ___      ___ ___     //
//    |    \ / _ \ / _ \| | |    \| \ \ /\ / / / __|    //
//    | |\  \ (_) | (_) | | | |\  \ |\ V  V /| \__ \    //
//    \_| \_/\___/ \___/|_| \_| \_/_| \_/\_/ |_|___/    //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract KKP is ERC1155Creator {
    constructor() ERC1155Creator("Kool Kiwi Project", "KKP") {}
}
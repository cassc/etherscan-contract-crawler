// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seven
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//     @@@@@@   @@@@@@@@  @@@  @@@  @@@@@@@@  @@@  @@@      //
//    @@@@@@@   @@@@@@@@  @@@  @@@  @@@@@@@@  @@@@ @@@      //
//    [email protected]@       @@!       @@!  @@@  @@!       @@[email protected][email protected]@@      //
//    [email protected]!       [email protected]!       [email protected]!  @[email protected]  [email protected]!       [email protected][email protected][email protected]!      //
//    [email protected]@!!    @!!!:!    @[email protected]  [email protected]!  @!!!:!    @[email protected] [email protected]!      //
//     [email protected]!!!   !!!!!:    [email protected]!  !!!  !!!!!:    [email protected]!  !!!      //
//         !:!  !!:       :!:  !!:  !!:       !!:  !!!      //
//        !:!   :!:        ::!!:!   :!:       :!:  !:!      //
//    :::: ::    :: ::::    ::::     :: ::::   ::   ::      //
//    :: : :    : :: ::      :      : :: ::   ::    :       //
//                                                          //
//    by Sashelka                                           //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SINS is ERC721Creator {
    constructor() ERC721Creator("Seven", "SINS") {}
}
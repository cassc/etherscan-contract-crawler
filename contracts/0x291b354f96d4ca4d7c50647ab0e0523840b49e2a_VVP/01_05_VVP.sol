// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ViViP CreArts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     _    _  __  ___   __    ___      //
//    ( \/\/ )/  \(  ,) (  )  (   \     //
//     \    /( () ))  \  )(__  ) ) )    //
//      \/\/  \__/(_)\_)(____)(___/     //
//       ___  ___   __   __  ___        //
//      (  ,\(  _) (  ) / _)(  _)       //
//       ) _/ ) _) /__\( (_  ) _)       //
//      (_)  (___)(_)(_)\__)(___)       //
//                                      //
//                                      //
//////////////////////////////////////////


contract VVP is ERC721Creator {
    constructor() ERC721Creator("ViViP CreArts", "VVP") {}
}
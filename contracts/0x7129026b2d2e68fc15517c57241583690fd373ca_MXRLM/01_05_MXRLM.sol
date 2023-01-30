// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monsters vs Robots by LM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//         (  \/  )/  \( \( )/ __)(_  _)(  _)(  ,)       //
//          )    (( () ))  ( \__ \  )(   ) _) )  \       //
//         (_/\/\_)\__/(_)\_)(___/ (__) (___)(_)\_)      //
//        _  _  ___    ___   __  ___   __  ____  ___     //
//       ( )( )/ __)  (  ,) /  \(  ,) /  \(_  _)/ __)    //
//        \\// \__ \   )  \( () )) ,\( () ) )(  \__ \    //
//        (__) (___/  (_)\_)\__/(___/ \__/ (__) (___/    //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract MXRLM is ERC721Creator {
    constructor() ERC721Creator("Monsters vs Robots by LM", "MXRLM") {}
}
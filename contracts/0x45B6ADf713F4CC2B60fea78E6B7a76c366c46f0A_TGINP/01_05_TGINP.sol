// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Glitch in the Past
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//        ____                         //
//            o8%8888,                 //
//          o88%8888888.               //
//         8'-    -:8888b              //
//        8'         8888              //
//       d8.-=. ,==-.:888b             //
//       >8 `~` :`~' d8888             //
//       88         ,88888             //
//       88b. `-~  ':88888             //
//       888b ~==~ .:88888             //
//       88888o--:':::8888             //
//       `88888| :::' 8888b            //
//       8888^^'       8888b           //
//      d888           ,%888b.         //
//     d88%            %%%8--'-.       //
//    /88:.__ ,       _%-' ---  -      //
//        '''::===..-'   =  --.        //
//                                     //
//                                     //
/////////////////////////////////////////


contract TGINP is ERC721Creator {
    constructor() ERC721Creator("The Glitch in the Past", "TGINP") {}
}
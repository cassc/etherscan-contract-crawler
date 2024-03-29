// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metamorph
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//    ___________________________________________________________________________________________________________                        //
//     _____/\\\\\\\\\_______________/\\\\____________/\\\\__/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\\\_____/\\\\\\\\\____                       //
//      ___/\\\\\\\\\\\\\____________\/\\\\\\________/\\\\\\_\/\\\///////////__\///////\\\/////____/\\\\\\\\\\\\\__                      //
//       __/\\\///\\\///\\\___________\/\\\//\\\____/\\\//\\\_\/\\\___________________\/\\\________/\\\/////////\\\_                     //
//        _\/\\\_\/\\\_\/\\\___________\/\\\\///\\\/\\\/_\/\\\_\/\\\\\\\\\\\___________\/\\\_______\/\\\_______\/\\\_                    //
//         _\/\\\\\\\\\\\\\\\___________\/\\\__\///\\\/___\/\\\_\/\\\///////____________\/\\\_______\/\\\\\\\\\\\\\\\_                   //
//          _\/\\\\\\\\\\\\\\\___________\/\\\____\///_____\/\\\_\/\\\___________________\/\\\_______\/\\\/////////\\\_                  //
//           _\/\\\\\\\\\\\\\\\___________\/\\\_____________\/\\\_\/\\\___________________\/\\\_______\/\\\_______\/\\\_                 //
//            _\/\\\///\\\///\\\___________\/\\\_____________\/\\\_\/\\\\\\\\\\\\\\\_______\/\\\_______\/\\\_______\/\\\_                //
//             _\///__\///__\///____________\///______________\///__\///////////////________\///________\///________\///__               //
//              ___________________________________________________________________________________________________________              //
//               __/\\\\____________/\\\\_______/\\\\\_________/\\\\\\\\\______/\\\\\\\\\\\\\____/\\\________/\\\_____/\\\__             //
//                _\/\\\\\\________/\\\\\\_____/\\\///\\\_____/\\\///////\\\___\/\\\/////////\\\_\/\\\_______\/\\\____\/\\\__            //
//                 _\/\\\//\\\____/\\\//\\\___/\\\/__\///\\\__\/\\\_____\/\\\___\/\\\_______\/\\\_\/\\\_______\/\\\____\/\\\__           //
//                  _\/\\\\///\\\/\\\/_\/\\\__/\\\______\//\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\\\\\____\/\\\__          //
//                   _\/\\\__\///\\\/___\/\\\_\/\\\_______\/\\\_\/\\\//////\\\____\/\\\/////////____\/\\\/////////\\\____\/\\\__         //
//                    _\/\\\____\///_____\/\\\_\//\\\______/\\\__\/\\\____\//\\\___\/\\\_____________\/\\\_______\/\\\____\///___        //
//                     _\/\\\_____________\/\\\__\///\\\__/\\\____\/\\\_____\//\\\__\/\\\_____________\/\\\_______\/\\\___________       //
//                      _\/\\\_____________\/\\\____\///\\\\\/_____\/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_____/\\\__      //
//                       _\///______________\///_______\/////_______\///________\///__\///______________\///________\///_____\///___     //
//                        ___________________________________________________________________________________________________________    //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MTMRPH is ERC721Creator {
    constructor() ERC721Creator("Metamorph", "MTMRPH") {}
}
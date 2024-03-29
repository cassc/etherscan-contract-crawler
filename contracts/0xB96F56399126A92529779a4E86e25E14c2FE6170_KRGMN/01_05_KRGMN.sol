// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dave Krugman Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//    __/\\\________/\\\____/\\\\\\\\\______/\\\________/\\\_____/\\\\\\\\\\\\__/\\\\____________/\\\\_____/\\\\\\\\\_____/\\\\\_____/\\\___________             //
//     _\/\\\_____/\\\//___/\\\///////\\\___\/\\\_______\/\\\___/\\\//////////__\/\\\\\\________/\\\\\\___/\\\\\\\\\\\\\__\/\\\\\\___\/\\\___________            //
//      _\/\\\__/\\\//_____\/\\\_____\/\\\___\/\\\_______\/\\\__/\\\_____________\/\\\//\\\____/\\\//\\\__/\\\/////////\\\_\/\\\/\\\__\/\\\___________           //
//       _\/\\\\\\//\\\_____\/\\\\\\\\\\\/____\/\\\_______\/\\\_\/\\\____/\\\\\\\_\/\\\\///\\\/\\\/_\/\\\_\/\\\_______\/\\\_\/\\\//\\\_\/\\\___________          //
//        _\/\\\//_\//\\\____\/\\\//////\\\____\/\\\_______\/\\\_\/\\\___\/////\\\_\/\\\__\///\\\/___\/\\\_\/\\\\\\\\\\\\\\\_\/\\\\//\\\\/\\\___________         //
//         _\/\\\____\//\\\___\/\\\____\//\\\___\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\____\///_____\/\\\_\/\\\/////////\\\_\/\\\_\//\\\/\\\___________        //
//          _\/\\\_____\//\\\__\/\\\_____\//\\\__\//\\\______/\\\__\/\\\_______\/\\\_\/\\\_____________\/\\\_\/\\\_______\/\\\_\/\\\__\//\\\\\\___________       //
//           _\/\\\______\//\\\_\/\\\______\//\\\__\///\\\\\\\\\/___\//\\\\\\\\\\\\/__\/\\\_____________\/\\\_\/\\\_______\/\\\_\/\\\___\//\\\\\___________      //
//            _\///________\///__\///________\///_____\/////////______\////////////____\///______________\///__\///________\///__\///_____\/////____________     //
//    __/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\_____/\\\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\\\\\\\\\_______/\\\\\_______/\\\\\_____/\\\_____/\\\\\\\\\\\___                  //
//     _\/\\\///////////__\/\\\////////\\\__\/////\\\///__\///////\\\/////__\/////\\\///______/\\\///\\\____\/\\\\\\___\/\\\___/\\\/////////\\\_                 //
//      _\/\\\_____________\/\\\______\//\\\_____\/\\\___________\/\\\___________\/\\\_______/\\\/__\///\\\__\/\\\/\\\__\/\\\__\//\\\______\///__                //
//       _\/\\\\\\\\\\\_____\/\\\_______\/\\\_____\/\\\___________\/\\\___________\/\\\______/\\\______\//\\\_\/\\\//\\\_\/\\\___\////\\\_________               //
//        _\/\\\///////______\/\\\_______\/\\\_____\/\\\___________\/\\\___________\/\\\_____\/\\\_______\/\\\_\/\\\\//\\\\/\\\______\////\\\______              //
//         _\/\\\_____________\/\\\_______\/\\\_____\/\\\___________\/\\\___________\/\\\_____\//\\\______/\\\__\/\\\_\//\\\/\\\_________\////\\\___             //
//          _\/\\\_____________\/\\\_______/\\\______\/\\\___________\/\\\___________\/\\\______\///\\\__/\\\____\/\\\__\//\\\\\\__/\\\______\//\\\__            //
//           _\/\\\\\\\\\\\\\\\_\/\\\\\\\\\\\\/____/\\\\\\\\\\\_______\/\\\________/\\\\\\\\\\\____\///\\\\\/_____\/\\\___\//\\\\\_\///\\\\\\\\\\\/___           //
//            _\///////////////__\////////////_____\///////////________\///________\///////////_______\/////_______\///_____\/////____\///////////_____          //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KRGMN is ERC1155Creator {
    constructor() ERC1155Creator("Dave Krugman Editions", "KRGMN") {}
}
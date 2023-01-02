// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Freaklion Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    F                    //
//    Fr                   //
//    Fre                  //
//    Frea                 //
//    Freak                //
//    Freakl               //
//    Freakli              //
//    Freaklio             //
//    Freaklion            //
//    Freaklion E          //
//    Freaklion Ed         //
//    Freaklion Edi        //
//    Freaklion Edit       //
//    Freaklion Editi      //
//    Freaklion Editio     //
//    Freaklion Edition    //
//                         //
//                         //
/////////////////////////////


contract FrkEd is ERC1155Creator {
    constructor() ERC1155Creator("Freaklion Editions", "FrkEd") {}
}
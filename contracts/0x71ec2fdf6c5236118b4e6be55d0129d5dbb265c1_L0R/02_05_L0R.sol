// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Loyalty over Royalty
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    8 8888         ,o888888o.  `8.`8888.      ,8'    .8.          8 8888   8888888 8888888888 `8.`8888.      ,8'         //
//    8 8888      . 8888     `88. `8.`8888.    ,8'    .888.         8 8888         8 8888        `8.`8888.    ,8'          //
//    8 8888     ,8 8888       `8b `8.`8888.  ,8'    :88888.        8 8888         8 8888         `8.`8888.  ,8'           //
//    8 8888     88 8888        `8b `8.`8888.,8'    . `88888.       8 8888         8 8888          `8.`8888.,8'            //
//    8 8888     88 8888         88  `8.`88888'    .8. `88888.      8 8888         8 8888           `8.`88888'             //
//    8 8888     88 8888         88   `8. 8888    .8`8. `88888.     8 8888         8 8888            `8. 8888              //
//    8 8888     88 8888        ,8P    `8 8888   .8' `8. `88888.    8 8888         8 8888             `8 8888              //
//    8 8888     `8 8888       ,8P      8 8888  .8'   `8. `88888.   8 8888         8 8888              8 8888              //
//    8 8888      ` 8888     ,88'       8 8888 .888888888. `88888.  8 8888         8 8888              8 8888              //
//    8 888888888888 `8888888P'         8 8888.8'       `8. `88888. 8 888888888888 8 8888              8 8888              //
//                                                                                                                         //
//        ,o888888o.  `8.`888b           ,8' 8 8888888888   8 888888888o.                                                  //
//     . 8888     `88. `8.`888b         ,8'  8 8888         8 8888    `88.                                                 //
//    ,8 8888       `8b `8.`888b       ,8'   8 8888         8 8888     `88                                                 //
//    88 8888        `8b `8.`888b     ,8'    8 8888         8 8888     ,88                                                 //
//    88 8888         88  `8.`888b   ,8'     8 888888888888 8 8888.   ,88'                                                 //
//    88 8888         88   `8.`888b ,8'      8 8888         8 888888888P'                                                  //
//    88 8888        ,8P    `8.`888b8'       8 8888         8 8888`8b                                                      //
//    `8 8888       ,8P      `8.`888'        8 8888         8 8888 `8b.                                                    //
//     ` 8888     ,88'        `8.`8'         8 8888         8 8888   `8b.                                                  //
//        `8888888P'           `8.`          8 888888888888 8 8888     `88.                                                //
//                                                                                                                         //
//    8 888888888o.      ,o888888o.  `8.`8888.      ,8'    .8.          8 8888   8888888 8888888888 `8.`8888.      ,8'     //
//    8 8888    `88.  . 8888     `88. `8.`8888.    ,8'    .888.         8 8888         8 8888        `8.`8888.    ,8'      //
//    8 8888     `88 ,8 8888       `8b `8.`8888.  ,8'    :88888.        8 8888         8 8888         `8.`8888.  ,8'       //
//    8 8888     ,88 88 8888        `8b `8.`8888.,8'    . `88888.       8 8888         8 8888          `8.`8888.,8'        //
//    8 8888.   ,88' 88 8888         88  `8.`88888'    .8. `88888.      8 8888         8 8888           `8.`88888'         //
//    8 888888888P'  88 8888         88   `8. 8888    .8`8. `88888.     8 8888         8 8888            `8. 8888          //
//    8 8888`8b      88 8888        ,8P    `8 8888   .8' `8. `88888.    8 8888         8 8888             `8 8888          //
//    8 8888 `8b.    `8 8888       ,8P      8 8888  .8'   `8. `88888.   8 8888         8 8888              8 8888          //
//    8 8888   `8b.   ` 8888     ,88'       8 8888 .888888888. `88888.  8 8888         8 8888              8 8888          //
//    8 8888     `88.    `8888888P'         8 8888.8'       `8. `88888. 8 888888888888 8 8888              8 8888          //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract L0R is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
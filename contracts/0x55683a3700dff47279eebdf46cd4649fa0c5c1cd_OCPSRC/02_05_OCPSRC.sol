// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On-Chain Press / Source Concepts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                     __,╓@╢N╖,_                             //
//                                                _ ╓╥@╣▒▒▒▒▒▒▒▒▒╢╗╖                          //
//                                            ,╓╗@╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╬                        //
//                          _ ,▄_      _ ,╓╗╢╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╢╢╣╣╢╣_                       //
//                     __▄▄▄██████▄▄,╔@╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╢╢╣╣╣╣╣╢╣╣╣_                       //
//                   ▄██████████▀▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╢╢╣╣╢╣╣╣╣╣╣╣╣╣╣╢                        //
//                   █████████▒▒▒╣╣▒▒▒▒▒▒▒▒▒▒▒╢╢╢╢╢╣╣╣╣╣╢╣╣╣╣╣╣╣╣╣╢╣╣╣                        //
//                   █████████▒▒▒▒▒▒▒▒╣▒▒╢╢╢╢╣╣╣╣╣╣╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣_                       //
//                  _█████████▒▒▒▒▒▒▒▒▒╢╣╣╣╣╣╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╢╣╣╣╣╢╢╢╢╢                        //
//                   █████████▒▒▒▒▒▒▒▒▒╢╢╣╣╣╢╣╢╣╣╣╣╢╣╣╣╣╢╢╢╢▒╢╢╢╣╢╢╢╢╣▄,_                     //
//                   █████████▒▒▒▒▒▒▒▒▒╢╣╣╣╣╣╣╣╢╣╢╢╣╢╢▒▓▓██████▓▒╢╢╢╢╢▓▓▓▓▄▄,_                //
//                  _█████████▒▒▒▒▒▒▒▒▒╢╢╣╣╣╣╣╣╣╢╢▓▓███████████████▓▓▒▓▓▓▓▓▓▓▓▓▄g             //
//                  _█████████▒▒▒▒▒▒▒▒▒╢╢╢╣╢╣╢╢╢╢▓███████████████████████▓▓▓▓▓▓▓▓▓▓▄▄,_       //
//                  _█████████▒▒▒▒▒▒▒▒▒╢╣╣╢╢╢╢╢╢╢▓███████████████████████████▓▓▓▓▓▓▓▓▓▓▓▄▄    //
//                  _████▓▓▓▓▓▒▒▒▒▒▒▒▒▒╢╢╢╢╣╢╢╢╢╢▓█████████████████████████████▌▓▓▓▓▓▓▓▓▓▓    //
//              _,╓▄▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒╢╣╣╣╣╣╢╢╢╢▓█████████████████████████████▓▓▓███▓▓▓▓▓    //
//          ,╓▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒╢╢╢╢╢╢╢╢╢╢▓████████████████████████████████████▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▒▒▒▒▒▒▒╢╢╢╢╢╢╢╢▓▓█████████████████████████████████████▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒╢╢╢▒▓▓███▓▓▓▓▓█████████████████████████████████▓▓▓▓    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████████████▓█▀▀    //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████████▀▀╙        //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████▀`_            //
//        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████⌐              //
//        _╙╙▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████⌐              //
//              ╙▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████⌐              //
//                 _ ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████⌐              //
//                  _██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████⌐              //
//                  _█████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████████████████⌐              //
//                   █████████╣╣╣▒▒▓▓▓▓▓▓▓▓▓▒╢╣╢╢▓█████████████████████████████⌐              //
//                  _█████████╣╣╣╣╢╣╣╢▒▒╣╣╢╢╣╣╢╣╢╢▒▀▀██████████████████████████⌐              //
//                  _█████████╣╣╣╣╣╣╣╣╣╢╣╣╣╢╢╢╣╢╢╢╢╢╢╢╢▒▀██████████████████████⌐              //
//                  _█████████╣╣╣╣╣╣╣╣╣╢╢╢╣╢╢╣╢╢╢╣╢╣╣╣╢╣╢╢╢╢▒▀██████████████▀▀└               //
//                  _█████████╣╣╣╣╣╣╣╣╣╢╣╣╢╣╢╢╢╢╢╣╣╢╢╣╣╢╢╣╢Ñ╝╙___▐▀████▀▀└                    //
//                  _█████████╣╣╣╣╣╣╣╣╣╢╣╢╣╣╢╢╢╣╢╢╢╣╢╣╩╝╙ _         _                         //
//                  _█████████▄▒╣╣╣╣╣╣╣╢╢╣╢╢╢╣╣╣▓╩╩`                                          //
//                  _█████████████▄▄▒╣╣╢╢╣╣▓╩╙                                                //
//                   ██████████████████▄▌ _                                                   //
//                   ████████████████████                                                     //
//                   ████████████████████                                                     //
//                   ████████████████████                                                     //
//                    ¬▀▀████████████▀▀╙                                                      //
//                         ╙▀▀██▀▀-                                                           //
//                                                                                            //
//                                                                                            //
//    ______________________                                                                  //
//    http://onchainpress.io                                                                  //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract OCPSRC is ERC721Creator {
    constructor() ERC721Creator("On-Chain Press / Source Concepts", "OCPSRC") {}
}
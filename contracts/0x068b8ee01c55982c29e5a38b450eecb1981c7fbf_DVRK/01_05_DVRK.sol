// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DVRK ARTS, 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                             /##########################################################    #####                             //
//                               ########################################################   .####/                              //
//                                                                                #####    #####                                //
//                                  #########################################    #####    #####                                 //
//                                   ######################################*   #####.   #####                                   //
//                                     #####             #######              #####    #####                                    //
//                                      #####    #####    ####      ,############/   #####                                      //
//                                       .####(   /####(    #         ##########    #####                                       //
//                                         #####    #####              /#######   /####,                                        //
//                                          /####/   (####,             #####    #####                                          //
//                                            #####    ############    #####   .####(                                           //
//                                             (####.   #########    #####    #####                                             //
//                                               #####    ######    #####    #####                                              //
//                                                #####    #####    ###,   #####                                                //
//                                                 .#####   ,#####   *    #####                                                 //
//                                                   #####    #####     #####.                                                  //
//                                                    *####(   (####(  #####                                                    //
//                                                      #####    #########/                                                     //
//                                                       (####*   #######                                                       //
//                                                         #####    ###(                                                        //
//                                                          #####.   #                                                          //
//                                                            #####                                                             //
//                                                             ####                                                             //
//                                                              .#                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                       __/\\\\\\\\\\\\_____/\\\________/\\\____/\\\\\\\\\______/\\\________/\\\_                              //
//                        _\/\\\////////\\\__\/\\\_______\/\\\__/\\\///////\\\___\/\\\_____/\\\//__                             //
//                         _\/\\\______\//\\\_\//\\\______/\\\__\/\\\_____\/\\\___\/\\\__/\\\//_____                            //
//                          _\/\\\_______\/\\\__\//\\\____/\\\___\/\\\\\\\\\\\/____\/\\\\\\//\\\_____                           //
//                           _\/\\\_______\/\\\___\//\\\__/\\\____\/\\\//////\\\____\/\\\//_\//\\\____                          //
//                            _\/\\\_______\/\\\____\//\\\/\\\_____\/\\\____\//\\\___\/\\\____\//\\\___                         //
//                             _\/\\\_______/\\\______\//\\\\\______\/\\\_____\//\\\__\/\\\_____\//\\\__                        //
//                              _\/\\\\\\\\\\\\/________\//\\\_______\/\\\______\//\\\_\/\\\______\//\\\_                       //
//                                _\////////////___________\///________\///________\///__\///________\///__                     //
//                                                                                                                              //
//                                                                                                                              //
//                                                     1:1 Art collection, 2023                                                 //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DVRK is ERC721Creator {
    constructor() ERC721Creator("DVRK ARTS, 2023", "DVRK") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: colborn
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                ___________ _                                     //
//      \/                    __/   .::::.-'-(/-/)                                  //
//                         _/:  .::::.-' .-'\/\_`*******          __ (_))           //
//            \/          /:  .::::./   -._-.  d\|               (_))_(__))         //
//                         /: (""""/    '.  (__/||           (_))__(_))--(__))      //
//                          \::).-'  -._  \/ \\/\|                                  //
//                  __ _ .-'`)/  '-'. . '. |  (i_O                                  //
//              .-'      \       -'      '\|                                        //
//         _ _./      .-'|       '.  (    \\                         % % %          //
//      .-'   :      '_  \         '-'\  /|/      @ @ @             % % % %         //
//     /      )\_      '- )_________.-|_/^\      @ @ @@@           % %\/% %         //
//     (   .-'   )-._-:  /        \(/\'-._ `.     @|@@@@@            ..|........    //
//      (   )  _//_/|:  /          `\()   `\_\     |/[email protected]@             )'-._.-._.-    //
//       ( (   \()^_/)_/             )/      \\    /                /   /           //
//        )  _.-\\.\(_)__._.-'-.-'-.//_.-'-.-.)\-'/._              /                //
//    .-.-.-'   _o\ \\\     '::'   (o_ '-.-' |__\'-.-;~ ~ ~ ~ ~ ~~/   /\            //
//              \ /  \\\__          )_\    .:::::::.-'\          '- - -|            //
//         :::''':::::^)__\:::::::::::::::::'''''''-.  \                '- - -      //
//        :::::::  '''''''''''   ''''''''''''':::. -'\  \     COLBORNICORN          //
//    _____':::::_____________________________________\__\______________________    //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract colborn is ERC721Creator {
    constructor() ERC721Creator("colborn", "colborn") {}
}
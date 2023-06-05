// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sensual Vibes by Monica F.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//       _____                             __   _    ___ __                                                                                              //
//      / ___/___  ____  _______  ______ _/ /  | |  / (_) /_  ___  _____                                                                                 //
//      \__ \/ _ \/ __ \/ ___/ / / / __ `/ /   | | / / / __ \/ _ \/ ___/                                                                                 //
//     ___/ /  __/ / / (__  ) /_/ / /_/ / /    | |/ / / /_/ /  __(__  )                                                                                  //
//    /____/\___/_/ /_/____/\__,_/\__,_/_/     |___/_/_.___/\___/____/                                                                                   //
//        __  ___            _               ______           __  _ __            ___       _                                                            //
//       /  |/  /___  ____  (_)________ _   / ____/___  _____/ /_(_) /___  ______/ (_)___  (_)                                                           //
//      / /|_/ / __ \/ __ \/ / ___/ __ `/  / /_  / __ \/ ___/ __/ / __/ / / / __  / / __ \/ /                                                            //
//     / /  / / /_/ / / / / / /__/ /_/ /  / __/ / /_/ / /  / /_/ / /_/ /_/ / /_/ / / / / / /                                                             //
//    /_/  /_/\____/_/ /_/_/\___/\__,_/  /_/    \____/_/   \__/_/\__/\__,_/\__,_/_/_/ /_/_/                                                              //
//        __________  ______  ________  ___                                                                                                              //
//       / ____/ __ \/ ____/ /__  /__ \<  /                                                                                                              //
//      / __/ / /_/ / /  ______/ /__/ // /                                                                                                               //
//     / /___/ _, _/ /__/_____/ // __// /                                                                                                                //
//    /_____/_/ |_|\____/    /_//____/_/                                                                                                                 //
//                                                                                                                                                       //
//                                                                                                                                                       //
//    Artmonica.eth © Monica Fortitudini                                                                                                                 //
//    artmonica.xys                                                                                                                                      //
//    t.me/monicaforti                                                                                                                                   //
//                                                                                                                                                       //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkxdodxx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;..      .'ckNMMMMWNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;             .;ooc;''..',:lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOkxdddd;                             .:kNMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXkl,..                                       .cXMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXd'                                              :XMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMK;                    ......                      .xWMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMNc                .;:lox00kdo;'....                 lWMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMM0,                ,cldx00Okkxo:,''.                 lWMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMM0'                .,;:lxOOkkdl;,,...               .dMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMNl                 .,cdkxl:;;,;l:...               ,0MMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMK,                ..',,..;lodxxc'...             .xWMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKc.             ...  ..:dkkOOdcc;...           .xWMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNO:.           .. . .:dxxkOOo:oo'           .:0WMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:'.            .;dkkOOxlcdxl'.       .;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdc,..'....';lxkO0Odoodxkdc;'...'ckNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxdoll::clllodkOOkkxdddxxdooloodxddx0WMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKddxdolloddddxkkkkkOOOkkkkkkkkkkkOOxo:dNMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOllollodxxxxxkOOOOOOOOkkkkkkkOO00K0kdc;kWMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOccllodxxxkkkOOOOOkkkkkkkOOOkkkkkkxdoc,lXMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO::ccloodxxkO00Okkxxxxxxkkkkddolclllc:',OMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.....',:ldkOkxdollc:;;;,,,,''....... .dMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'        ..;cc;,'...                   cNMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                              .       ,KMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc                             :o.      .OMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo....                        ,0K,      .xMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. ...                      .kWNc      .dMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO' ...                     .oNMMd.      dMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO' ...                     ;KMMMO'      dMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. ....                   .xWMMMN:     .xMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,  ....                   :XMMMMWo     'OMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; ....                    .kMMMMMWd.    ;XMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc....                      ,KMMMMMNl     cNMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl...                        .oNMMMNo.    .kWMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd...                          .dWMNo.    .xWMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'..                            .ONl.    .kWMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,..                              ll.    .kWMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMX:..                               ..    'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNl...      MONICA FORTITUDINI            ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx. ..                                  .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMK;   .                                 .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMO.  .                                 'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWd.                                   ,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWl   ..                              'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMN:   .                              .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWl  .l:                             'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMO'  ;c.                            ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWd..':,.                           cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWkcld0l                          'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWK;                      .,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                   .lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                 ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.               ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;              ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.             'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:              :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                 //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SENSV is ERC721Creator {
    constructor() ERC721Creator("Sensual Vibes by Monica F.", "SENSV") {}
}
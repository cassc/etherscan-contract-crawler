// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Let's Move Mountains
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                               .:l.                                                                           //
//                                                                              xKNWKc                                                                          //
//                                                                           .cKMMMMMNx'                                                                        //
//                                                                          ,kWMMMMMMMWKc.                                                                      //
//                                                                        .lKMMMMMMMMMMMNk,                                                                     //
//                                                                       ,kWMMMMMMMMMMMMMMXl.                                                                   //
//                                                                     .oXMMMMKxKMMMMMMMMMMWk,                                                                  //
//                                                               ':lodkKWMMMWO,.kWWNWMMMMWWMMXo.                                                                //
//                                                             .oXMMMMMMMMMNd. .oXk;:kNMWkdKWMWO;                                                               //
//                                                            ;OWMWKxoo0WMKc.   .;.   ,dXx.'xNMMXd.    .                                                        //
//                                                          .oXMMWk'  .OWO,             ';.  ;kWMW0:..oKk,                                                      //
//                                                   .dOl..;OWMMNo.   lXx.                    .c0WMNO0WMMXo.                                                    //
//                                                 .:0WMWKOXMMMKc    ,kl.                       .xWMMMMMMMW0:                                                   //
//                                                'xNMMMMMMMMWO,    .;,                         ,OWMMNOdxXWMNx'                                                 //
//                                              .cKWNOKWMMMMNx.      .                        .lXWXkl'   'oKWWKl.                                               //
//                                             'xNXx,.cNMMMXl.                               ,x0x:.        .cONWO;                                              //
//                                           .cKXx,   ,KMMK:                                ':;.             .;xXXd'                                            //
//                                          ,k0d'     .kWk'                                                     'oK0l.                                          //
//                                        .lko'        :o.                                                        .lOx;                                         //
//                                       'lc.                                                                       .:dl.                                       //
//                                     .,;.                                                                            ':,                                      //
//                                     ..                                                                                ..                                     //
//                                _          _   _       __  __                  __  __                   _        _                                            //
//                               | |        | | ( )     |  \/  |                |  \/  |                 | |      (_)                                           //
//                               | |     ___| |_|/ ___  | \  / | _____   _____  | \  / | ___  _   _ _ __ | |_ __ _ _ _ __  ___                                  //
//                               | |    / _ \ __| / __| | |\/| |/ _ \ \ / / _ \ | |\/| |/ _ \| | | | '_ \| __/ _` | | '_ \/ __|                                 //
//                               | |___|  __/ |_  \__ \ | |  | | (_) \ V /  __/ | |  | | (_) | |_| | | | | || (_| | | | | \__ \                                 //
//                               |______\___|\__| |___/ |_|  |_|\___/ \_/ \___| |_|  |_|\___/ \__,_|_| |_|\__\__,_|_|_| |_|___/                                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LMM is ERC721Creator {
    constructor() ERC721Creator("Let's Move Mountains", "LMM") {}
}
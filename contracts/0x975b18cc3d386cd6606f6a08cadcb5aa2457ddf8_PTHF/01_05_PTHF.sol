// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Preto HF
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                        .:dooodddddoddddddddddddddddddddddddddddddddod:.                                        //
//                                        .OMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                        //
//                                     :xxONMMO;,,xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxx:                                     //
//                                    .xMMWNNNd.  lWMMMMMWNNNNNNNNNNNNNNNNWMMMMMMMMMMMMMMMMMx.                                    //
//                                 ;OO0NMM0:..:xOOXMMMMMM0:..............:0MMMMMMMMMMMMMMMMMN0OO;                                 //
//                                 cWMWXKKx,..cXMMMMMMMMMO.   ........   .OMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMXc..,xKKXWMMMMMMMMMO.  'kKKKKKKO'  .OMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMX;  .OMMMMMMMMMMMMMO.  'xOOOOOOx'  .OMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMX;  .OMMMMMMMMMMMMMO.              .OMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMNo,,cKMMMMMMMMMMMMMO.  .',,,,,,,,,,cKMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMMMWWWMMMMMMMMMMMMMMO.  ;KWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMMMMMMMMMMMMMMMMMMMMO.  ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMMMMMMMMMMMMMMMMMMMMO.  ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMMMMMMMMMMMMMMMMMMMMXdllkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWc                                 //
//                                 cWMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMWc                                 //
//                                 cWMMMMMKc,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,cKMMMMMWc                                 //
//                                 lWMMMMMO'                                            'OMMMMMWl                                 //
//                  ;kOOOOOOOOOOOOOXMMMMMMN0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0NMMMMMMXOOOOOOOOOOc                      //
//                  cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd.                     //
//                  cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                      //
//                  cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                      //
//                  cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd                      //
//                  ,xxxxxxxxxxxxxxKMMW0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0WMMKxxxxxxxxxx:                      //
//                                 lWMX;                                                    ;XMWl                                 //
//                                 cWMX;      .;:;.   '::,       .;::::::::::.              ;XMWc                                 //
//                                 lWMX;      ;XMWc  .dMMO.      cNWMMMMMMMMMd              ;XMWc                                 //
//                             .:llOWMX;      ;XMWl  .dMMO.      cNWMNkllllll,              ;XMWc                                 //
//                             ;XMMMMMX;      ;XMWc  .dMMO.      cNWMX;                     ;XMWc                                 //
//                             ;XMWk::;.      ;XMW0doxKMMO.      cNWMWOod:.                 ;XMWc                                 //
//                             ;XMWc          ;XMMMWWWMMMO.      cNWMMWWWO.                 ;XMWc                                 //
//                             ;XMWc          ;XMWx,,;OWMO.      cNWMNo,,.                  ;XMWc                                 //
//                             ;XMWc          ,0NXc   oNNk.      :KXN0,                     ;XMWc                                 //
//                             ;XMWc           ....   ....        ....                      ;XMWc                                 //
//                             ;XMWl                                                  ......cXMWc                                 //
//                             ;XMWl                                                 lKKKKKKXWMWc                                 //
//                             ;XMWd'......    .........'.    ............    ......,kMMMMMMN0Ok;                                 //
//                             ;XMMWNNNNNNx.  ,0NNNNNNNNNx.  ,0NNNNNNNNNNk.  ,0NNNNNNWMMMMMMx.                                    //
//                             .oxxxxxkXMMO.  ;XMWKxxkXMMO.  ;XMWKkxxkXMMO.  ;XMWKkxxxxxxxxx:                                     //
//                                    .xMMO.  ;XMWl  .xMMO.  ;XMWl   .dMMO.  ;XMWl                                                //
//                                     dMMKo::dNMWc   dMMKo::dNMWc    dMMKo::dNMWc   .::::::'                                     //
//                                     dMMMMMMMMMWc   dMMMMMMMMMWc   .dMMMMMMMMMWc  .dMMMMMMd                                     //
//                                     ,lllllllllc.   ,lllllllllc.    ,lllllllllc.   dMMXdll,                                     //
//                                                                                   dMMO.                                        //
//                                     ;od:.      'odl.          'lodl.      .ldo'   dMMO.                                        //
//                                     dMMO.      lWMX;          lNWMX;      ;XMWl  .xMMO.                                        //
//                                     dMMNOxxxxxxKWMW0xxxxxxxxxxKWWMW0xxxxxx0WMWKxxkXMMO.                                        //
//                                     oNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNk.                                        //
//                                     ..........................................'.....'.                                         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PTHF is ERC721Creator {
    constructor() ERC721Creator("Preto HF", "PTHF") {}
}
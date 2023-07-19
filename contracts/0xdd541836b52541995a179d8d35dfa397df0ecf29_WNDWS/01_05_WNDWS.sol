// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Windows Polaroids
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//     .:c::::::::::::::::::::::::::::::::::::::::::::;.          .;c:::::::::::::::::::::::::::::::::::::::::::::.                                                                                     //
//                                             'loollllllllllllllllllllllllllllllllllllllllllol.          .cdooooooooooooooooooooooooolooooooooooooolloooo,                                             //
//                                             'loc.........................................;ol.          .col,........................................,lo'                                             //
//                                             'lo:.                                        ,oc.          .col.                                        .lo'                                             //
//                                             'lo:.                                        ,oc.          .:ol.                                        .lo'                                             //
//                                             'lo:.                                        ,oc.          .:ol.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .:ol.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .col.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,oc.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .coc.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .col.                                        .lo,                                             //
//                                             'lo:.                                        ,ol.          .cdl.                                        .lo,                                             //
//                                             'lo:.                                        ,ol.          .col.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .col.                                        .lo'                                             //
//                                             'lo:.                                        ,ol.          .col.                                        .lo'                                             //
//                                             'loc;,,,,,,,,,,,,,,,''''''''''',,,,,,,,,,,,,,:oc.          .col;'''''''''''''''''''''''''''''''''''''''';lo'                                             //
//                                             'loooooooooooooooooooooooooooooooooooooooooooooc.          .coooooooooooooooooooooooooooooooooooooooooooool'                                             //
//                                             'loooooooooooooooooooooooooooooooooooooooooooooc.          .coooooooooooooooooooooooooooooooooooooooooooooo'                                             //
//                                             'loooooooooooooooooooooooooooooooooooooooooooooc.          .cdooooooooooooooooooooooooooooooooooooooooooooo'                                             //
//                                             'ldooooooooooooxOOkdoooooooooooooooooooooooooooc. ..       .cdooooooooooooooooooooooooooooooooooooooooooooo'                                             //
//                                             'ododddoooooookKKKXkooooxOxooooooooooooooooooodl..ck;      .cdooooooooooooooooooooooooooooooooooooooooooooo,                                             //
//                                             .,,,:kOc,,,,,,clcxXd,,,,;:;,,,,,,,,,,,,,,,,,,,,'. lKo.     .',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;lodoc;,,,,,,,,.                                             //
//                                                 'kO,        .dK:           ...',.             cKo.       ....                          'xOxdxo.                                                      //
//                                                 :Kd.,dl.   .c0x.   ;l'    'xOkO0x'         ..;dKx.     .:xkkxo,     'l;    .  ;do:.    ,k0o;'.                                                       //
//                                                .dKll0XO;  .l0x'   .oK:    ,OXk;c0x'       .lOkdOKxl:.  .lKOldKd.    :Kd.  ;xo,;o0Kc     .:dkko:'.                                                    //
//                                                ,OKO0dkKc.;kOl.     ;l'    'dd' .:kkxd;    :0KxdOOxdc.   :0Oxkx,     'kO;'lOOxxxxxl.    ....,cd00koc,.                                                //
//                                             .;;o0XKxco00O0Oo:;;;;;;;;;;;;;;::;;;;cdkxc;;;;cdl::,..     .;dkkdc;;;;;;:d0OO0kl:ccc:;;;;;:okkkkkkOKK00kc;;.                                             //
//                                             'oddxkxdoddxxdoooooooooooooooooooooooooooooooool.          .cdooooooooooooddddooooooooooooodddddddddddooooo,                                             //
//                                             'loc,''''''''''''''''''''''''''''''''''''''',cdl.          .cooc::::::::::::::::::::::::::::::::::::::::coo,                                             //
//                                             'lo:.                                        ;dc.          .col;'''''''''''''''''''''''''''''''''''''''';oo'                                             //
//                                             'lo:.                                        ;oc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.                                        ;oc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;oc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;oc.          .col;'''''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.                                        ;oc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo;.                                        ;dl.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.                                        ;dl.          .col;','''''''''''''''''''''''''''''''''''',';oo,                                             //
//                                             'lo:.                                        ;dl.          .col;','''''''''''''''''''''''''''''''''''',';oo,                                             //
//                                             'lo:.                                        ;dl.          .col;','''''''''''''''''''''''''''''''''''',';oo,                                             //
//                                             'lo:.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.                                        ;dc.          .col;','''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.                                        ;dc.          .col;'''''''''''''''''''''''''''''''''''''',';oo'                                             //
//                                             'lo:.........................................:oc.          .col:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:oo'                                             //
//                                             'lolllllllllllllllllllcclllllllllllllllllllllloc.          .cooollllloollllllllllllllllllllllllllllllllllol'                                             //
//                                             'loooooooooooooooooooooooooooooooooooooooooooooc.          .coooooooooooooooooooooooooooooooooooooooooooooo'                                             //
//                                             'loooooooooooooooooooooooooooooooooooooooooooooc.          .cdooooooooooooooooooooooooooooooooooooooooooooo'                                             //
//                                             'loooooooooooooooooooooooooooooooooooooooooooooc.          .cdooooooooooooooooooooooooooooooooooooooooooooo'                                             //
//                                             'odooooooooooooooooooooooooooooooooooooooooooodl.          .cdooooooooooooooooooooooooooooooooooooooooooooo,                                             //
//                                             .,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,.          .,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;.                                             //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WNDWS is ERC721Creator {
    constructor() ERC721Creator("Windows Polaroids", "WNDWS") {}
}
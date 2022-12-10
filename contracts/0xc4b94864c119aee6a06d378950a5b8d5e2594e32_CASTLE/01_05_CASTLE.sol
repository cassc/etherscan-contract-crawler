// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lil Castle
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                 ..                                                         //
//                                             .,ok0Okkxxxoc.                                                 //
//                                            .oXMMMMMMMMMMWKl.               .                               //
//                                           .lNMMMW0ddOXNMMMNo.         . .'....                             //
//                                           :XWWWXl.  'lOMMWWk'      ....;lxdc;,.                            //
//                                          .oXNX0Oc. .lkkk0x;,.      ..:dOKK0kod:..                          //
//                                           .lOO0NXxoOKOd:o:.         ,x0koodxo;,'..                         //
//                                             .lXWXKXWWNNNNKd.        ;xk0KXX0d,...                          //
//                                            .',,;cONWWMMMKd;.        'coKWMWKd'...                          //
//                                       .'. .dKl. :kxxkdxx;           ..,o0Kxc'.                             //
//                                      .oKKolxo'  ...'....             .':;,'. ''                            //
//                                   .'okkKWWWXd.                        ..    .',.                           //
//                                  .o00O0NMNNWW0l;.                     .,,..;:,;'....                       //
//                                 'xOkxloKWWNXNWKo;..                   .cl;cdddl,,;,''.                     //
//                                ,lxOlcONNN0kk0Odokx'                    ,l:,,;;,:c,.                        //
//                                ckl:dONNkddddxxdKW0;                .'.':ldd:.....                          //
//                               ,dxkddKN0xl,:kOc.,dX0:.            .;x0o,,oOk:.                              //
//                               .lxokXWNklldxOk:.  ,xKd;.       .,:cc:'..cko,.                               //
//                                .;xKXkoxkxxK0oxl.  .;kKk;.  .,cl:'.   .ox,                                  //
//                                  ;0WKd;,lxxc.cO:    .'cko..::'.    .;kx'                                   //
//                                  ,l::oxkx;   .cx;  ...,lkk:.      'dOl.                                    //
//                                'oOc   ....     ck:'oOOx;'o0d'  .'cOO;                                      //
//                                .dx,            'kdcl;..  .:O0l'l00d.                                       //
//                              ..cd;            .;:.         ;xc:k0l.                                        //
//                              ,kKk;       ..,cdO0o,,.        .....                                          //
//                              ,xo..   .;oxkOOxdodo:c,                                                       //
//                         ..  .d0c..,okOOxl;'.   'clkO:.. .;o;                                               //
//                        'od:,:docddlcl:..        ..l00Oxx0NNd,c;                                            //
//                       .dXWNolocdKWXc     ..':loodkkkkOKk::oc,lc.                                           //
//                       .:ONXocoxXWNOc,:cldOKK0Oxoc;....ckc.'ldodo'                                          //
//                         .xXxxOOOko:;xXOkdl:,..        .lOc..:d00x;.                                        //
//                        .cXNxoO0c.'ckOo..               .lOc.  .l0Ko.                                       //
//                        .cko,,xXO;.....                  .lO:    .lkkc.                                     //
//           .............',;,',;::,........'.              .;d;     .lkd,                                    //
//                                         ...                'dc.     'okl.                                  //
//                                         ..                 .o0o,.    .;xxl'                                //
//                  ..      .       .......'.......            ,coo;;:,'. .ckOl.                              //
//       .......................    ................',.          .';dkkkxc'.'o0kl,.                           //
//                                                  .;.             ...';:'...;0NO;.                          //
//                                                  .'.                       .odcl;.',;;'.....               //
//           .........      ..................... ...,,....... ..              ...:,':dkkxo:;l:.              //
//         ............     ................ .... ..........   ',                   ..'',,;'.,:,.             //
//                                                             .'                              .              //
//                                                             .'                                             //
//                                                              .                                             //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CASTLE is ERC721Creator {
    constructor() ERC721Creator("Lil Castle", "CASTLE") {}
}
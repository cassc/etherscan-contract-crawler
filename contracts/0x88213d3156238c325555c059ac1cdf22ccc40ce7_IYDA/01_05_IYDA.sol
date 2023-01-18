// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I.Y.Dark Alayra
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//                                               .',,'.                                ..','..                                              //
//                                                 .:c::;..                         .';:::'.                                                //
//                                                  'llcclc,.                     .;cc:co:.                                                 //
//                                                   ,ddllllc;.                .':lc:;ld:.                                                  //
//                                                   .cdddlcloc,.             ':lolccodc.                                                   //
//                                                    ;dddlcloolc'          .:loolccdo;.                                                    //
//                                                    ,ddddccooool,        .collol:lxl.                                                     //
//                                                    ,odddc:oollol'      .coolloc:lxdc'                                                    //
//                                                   .:coddc;lollcc;......,cclllo::oddd;                                                    //
//                                                   ..;oodo:;::::clllooolll:::::;lddlc,.                                                   //
//                                                    ,;':oc'',;:::;:loloc;;:::;'';ol;;l,                                                   //
//                                                    .,'..      ..'':ooc,''..     ...,'.                                                   //
//                                                         .       .;:;;::'       ..                                                        //
//                                                         .',,,,,;cl;..'cl:;,,,,,.                                                         //
//                                                           .,clolc:;..,:clooc;.                                                           //
//                                                              .','.',,'..,'..                                                             //
//                                                                  .;llc'                                                                  //
//                                                                   ;ooc.                                                                  //
//                                                                  .:ool'                                                                  //
//                                                                 .,clll;.                                                                 //
//                                                               .':cclllc:,.                                                               //
//                                                            ...';cloodolc:,...                                                            //
//                                                               .;loc:;cooc'.                                                              //
//                                                              .,cxo,',,cxl;'.                                                             //
//                                                           .':ll:ldc;;:oocclc,.                                                           //
//                                                          .:ooolccldddxoccclooc'                                                          //
//                                                          ;looo:coloxxdlol:loloc.                                                         //
//                                                          ;oooolccldxxdolccooooc.                                                         //
//                                                          'coooooc:loolcclooool;.                                                         //
//                                                          .;lolooollclcloooool:'.                                                         //
//                                                          .,:ooooolc:c:coooooc;.                                                          //
//                                                          .,;loool;;cc;,coool:;.                                                          //
//                                                           ':clool;:ooc;:oloc:;.                                                          //
//                                                           .::cool;:ooc;cool::'                                                           //
//                                                           .:::lol;:ooc:cooc:c.                                                           //
//                                                           .:l;col::ooc:lol;cc.                                                           //
//                                                         ..'coc:lo::ooc:loc:ll,..                                                         //
//                                                      .,:lcclolclo::ooc:loccoocclc;.                                                      //
//                                                    .;loollloolcco::ooc:ll:lololloolc;,''.....                                            //
//                                                   .cooooooooloc:l:;lo:;lc:looooooooolccooollcc;,,'..                                     //
//                                                   ;oooooloooooc:l:;co:;lcclooooooooooc'.'',;:cllooll:;'.                                 //
//                                                   .;loooooooooc:lc;co;;o::loooooololc'        ...,;:lool:,.                              //
//                                                     .,:looooooc:lc,:l;;l::ooooool:,..               ..,:lol:.                            //
//                                                     ..'cooooooc;ll;:c;:o::loooool,.                     .,col;.                          //
//                                                  .,:ccllclllc:::ll:,;;coc;;:lcccllc::,.                   .,loc'                         //
//                  ....''.''...                  .;ollccllloodocccccc:;ccccc:ldoolllc:lllc.                   .col,                        //
//              ...........'',,;;;;,'..           ;ddddoooddddddoolllodddolllodddddddooddddl.                   .col'                       //
//                               ..';:cc:,...    'odddddddddddddddddddddddddddddddddddddddddc.                   'loc.                      //
//                                    ..';:cc:;'.,clodddddddddddddddddddddddddddddddddddddddd:.                  .lol'                      //
//                                          ..,;;;::::cclodddddddddddddddddddddddddddddddddddo'                  .lol'                      //
//                                              .;:::::::::cccloddddddddddddddddddddddddddddddc.                 ;ool'                      //
//                                              .ldlccccccc::::::::cllooddddddddddddddddddddddo.                ,loo:.                      //
//                                              .cdoodddolcc::::ccc::::::::cclooddddddddddddddo'              .:lol;.                       //
//                                              .cdoodddooooolc:::::::ccllcc::::::c:::::ccllodl.          ..,clol;.                         //
//                                              .:oooooooooooollooolc::::::::ccclllccc:::::::::'''''',,;:clool:'.                           //
//                                               ,loooddoooodddoolloodddddlc:cccc;,,;::clllllcclooooollc:;,'..                              //
//                                               .cdoc'......',:cooodddddddodddl'.      ....,;,'''.....                                     //
//                                                :o;.          .'coddddddddddc.            'l,                                             //
//                                               .cl.             ;loddddddddo;             ,o,                                             //
//                                               .cl.            .cloddddddddoc,.          .co'                                             //
//                                               .:d;          .,clodol:clddddolc,.       .;od,                                             //
//                                                'oo,     .',:loodoc'   ..:oddooolc;,,,;:lodo,                                             //
//                                                .cdo:,,:cooooddddc.       ,oddddoooooooodddo'                                             //
//                                                 ,odddooddddddddd,         :dddddddddddddddc.                                             //
//                                                 .:oddddddddddddo.         ,oddddddddddol:,.                                              //
//                                                   .':llodddddddl.         ,odddddoc,'..                                                  //
//                                                       ..,ldddddo,   .,;  .cdddddd:.                                                      //
//                                                          ;ddddddl..,coo:;cddddddl.                                                       //
//                                                          .lddddddoooddddddddoodd:.                                                       //
//                                                           'lddddddc;codddddd:,:c.                                                        //
//                                                            ....,;,. ..:;,:;'                                                             //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IYDA is ERC721Creator {
    constructor() ERC721Creator("I.Y.Dark Alayra", "IYDA") {}
}
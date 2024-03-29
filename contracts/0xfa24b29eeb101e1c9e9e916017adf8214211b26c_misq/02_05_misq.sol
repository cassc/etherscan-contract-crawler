// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: misq meta blueprints
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                  .'',,''........'',,;,.                                                                                                                                        //
//                                                                                                                                            ....'clolc;,'..........':dl.                                        //
//                                                                                                                                      ...,cllc:;,'.....            .,c,                                         //
//                                                                                                                    .....    ...  ...''''......                    .,'                                          //
//                                                                                                              ...;llll:'.                                          '.                                           //
//                                                                                                           'loooc:;'...                                           'c'                                           //
//                                                                                                   .;lllllc::,....                                               .'::,'''''''',,;:cll'                          //
//                                                                                            .',,,,,;loc;,;;.                                                      ............'',;cc.                           //
//                                                                                        ....cxkxdol,..                                                                        ...;:.                            //
//                                                                                   .,cooolc:;;,.....                                                                           .''.                             //
//                                                                           ..',,,,,,;llc:;;'..                                                                                ..                                //
//                                                                       ...':oxxdoc:,'...                                                                                    ..                                  //
//                                                                 ..,cloolc:;,''....                                                                                        .                                    //
//                                                          ...,;::;;;;,''...                                                                                              ..                                     //
//                                                     ,clc:,'.....                                                                                                       ..                                      //
//                                                     .:dOOxdlc;'.                                                                                                      .'.                                      //
//                                                   .;ldkkxddxxkkxo;.                                                                                                   .;,                                      //
//                                               .;ldkkxdollcccclldxko,.                                                                                                 .,:;.                                    //
//                                           .,cdOOkxdolcc:;;;;;;;:cod:.                                                                                                  .';::,.                                 //
//                                        .;oOK0Okxdolc:;;,,''''''',,:;.                                                                                                    ..,:c;.                               //
//                                      .:OXX0Okxdolc:;;,''.............                                                                                                     ...,lc.                              //
//                                     .dXXK0Okxdlc:;,,''..............                                                                                                        .':c.                              //
//                                  .;lOXXK0Okdolc:;,'........                                                                         ..                                       .;;.                              //
//                              .;ldkKNXXK0Okdoc:;,''......                                                           ...             ..                                        .,.                               //
//                         .':lxOOkdkXNXK0Okdoc:;,'......                                                            ':,..                                                      .                                 //
//                     .':okOOkxdl:l0NXK0Okxol:;,'.....                                                            .cxoc,.                 ...                                 ..                                 //
//                    ,okO0OOkxolcckNXXK0Okxol:;,'....                                                             ,xOkxl,..               ',.                                .,.                                 //
//                      ..',;;::clxKNXKKK00kxoc;,'...                                                             .,dOkdc,..              ':.   ..                           .,.                                  //
//                                cKXK0O00KKOxoc;'...                                                            ..ckkxoc,..             .;.   .'..                          ..                                   //
//                                ;KKOxolloxk0koc;'..                                                            .;x0Okxoc;'..           ..   .,:,.                                                               //
//                                'OKkoc;'...:xOdc,..                                                           .. .:oxkxdc;,....             'ol'..''.                                                           //
//                                .dKko:,..   .oOxc,..                                                         .;.    .';::::;,'....          :xc',:lc.                  ..                                       //
//                                 ;00dc,..    .lOdc,..                                                        ':.          .................'ddccodxl'.                ..                                        //
//                                  lKko:,...   .dOd:'..                                                      .,'                    .....',;oxccdkOkl'....           ...                                         //
//                                  .d0xl:,'.....c0kl;..                                                      ..                            .,.',ck0x:,:oc,.         ..                                           //
//                                   .x0koc;,,,;:d00d:'..                                                    ..                                  .xOolxOOo;.       ...                                            //
//                                    .d0kdolclox0XKxl,..                                                   .,.                                  ;Od,l0Kkl,....   ..                                              //
//                                     .l00kxxxk0KXKkl;..                                                  .,'                                  .do. ,00dcc:''. ...                                               //
//                                       ,x00OO0KKK0xl;..                                                 ..'                                   ;:   :0kclko:'...                                                 //
//                                        .;x0K0000kdc,..                                                ...                                    .   .dOc.lOdc'..                                                  //
//                                           ,ok00Oxo:,...                                              ..                                          cx; 'kx:,.                                                    //
//                                             .,clool:,...                       ..                   .                                           .:. .lo. .                                                     //
//                                                 ..',,,,'....                ....,'.                .                                                .;.                                                        //
//                                                        ......................',:cl;.             ..                                                                                                            //
//                                                                 ....'',;;:::ccldxxc.           ...                                                                                                             //
//                                                                         ..';okkO0kl'.         ..                                                                                                               //
//                                                                             .cOK0xc'.  .    ...                                                                                                                //
//                                                                              .oX0d;'..'.   ..                                                                                                                  //
//                                                                               oKklcdl:,. ...                                                                                                                   //
//                                                                              'kOl,oOdc'...                                                                                                                     //
//                                                                             .oOc..xOo;'.                                                                                                                       //
//                                                                             cx, .lOl;,.                                                                                                                        //
//                                                                            .:.  :x;...                                                                                                                         //
//                                                                                .:.                                                                                                                             //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract misq is ERC1155Creator {
    constructor() ERC1155Creator("misq meta blueprints", "misq") {}
}
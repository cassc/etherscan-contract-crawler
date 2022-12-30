// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nebenzu Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    Nebenzu Editions                                                                                        //
//                                                                                                            //
//                                                                                                            //
//                                                                                     ..                     //
//                                                                               ...',;:;'..                  //
//                ....                                    .......             ..';clodxddoc;..                //
//            ...,;:;,..                               ..';:cll:,..         ..;lodxxxkOkxddl;.                //
//         ..;:codxxdol:'.                          ..;cloddxxddol;..      ..cdddxxkkOOOkxdl;.                //
//       .':lddddxxkxdddl,.            .           .;lododxxkkkddoc,.      .:lodxxxxxkxxxdo;..                //
//      .,oddxdxxxkkkxdxdc.      ...,::;,...      .;oddxxxxxxkxdddl,.      .:lloxddxxddxdo;.                  //
//     .'cdddxdolcoxkxdxdc'.    .,coddxxdoc,'..  .'coodxxdlldxxdxxl,.      ..';cdxxddxxdl,.                   //
//     .cdodxo:'.,lxxxdxdc'.  .':ldxxkOkkkxol:'...'cccolc;;lxxxdxdc'.       ..;lxxxkkkxl,'.......             //
//    .,odddd:...,lxxxxxo:.. .,cdddxkOOOkxxdddl,....','..':dxxxxxl,.        .,codkkOOkxoooollcc:;'..          //
//    .':lllc'..,cddddddl,. .'cddxxxxxxxxxxdodoc,.   ...';oxddxxd:..        .,codxkkkxxxddxdxxddddl;..        //
//     ..,,'...,lddddxdl,.. .,lddxxxxl:cdkxdoodo:..  ..,:ldddxxdc'.          .':lodxxxxxxxxxdxxxdxdoc,.       //
//        .....:dxddddo;.. ..,ldxdxxxl,,lxkxxxxdl,.  .'codxddxdl,.            ...',;;:cloloodxxxxdddoc,.      //
//          ..:oxddxxd:..  ..;oxxxkkkdc:lxkxxdddo:...':dxdddxxo;..    ....        . ........;ldkkxdddo:.      //
//         ..;oxdodxxl,.....,lxOOOOOkkxxxkkxxdddo;...:odxddxxdc'.....';c:;,..             ..':dkxxdddo:.      //
//        .':oxxddxkxl;,,;:loxkkOOOOOkkkkkxxxxdo;...'ldxxxxxxo;.',;codddoll:'.............';coxxxxdddl,.      //
//        .,ldxxkkOOxddddddxxxxxkkOkkxxxxxddddo;.. .,lddxxkkkdlloddxxxdoolll:;::::::c::cclodxxxddddddc..      //
//        .;oxxxxkOOxxxxddddddddxxxoooodddddlc,.   .,ldxxxxkkkxxxxddddxdolccllllloddxxxxxxxxxxdddddo:'.       //
//        .,cddxxxxxdddddddddddolc,'',:c::;,...     .:oddddxxxddddxxxdoc;..,:ccclooddddddddddddddl:,..        //
//        ..':lodddddddooooolc;'............        ..,:clodddddddolc;'.. ..';llooodddddddddoolc;'..          //
//          ...',;:cc:::;,,'....                      ....',;:;;;,....      ...,:clolllccc:;,'....            //
//              ............                                 ....               ............                  //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NebenzuEd is ERC1155Creator {
    constructor() ERC1155Creator("Nebenzu Editions", "NebenzuEd") {}
}
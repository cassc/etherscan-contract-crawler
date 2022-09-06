// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paladin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//                .,'   .:;.           .;:'   ',.                //
//               .:ox, .clc,           ,clc. ,xo:.               //
//               .clol.'lcl;           ;lcl'.lolc.               //
//        .',.   .;cdx:;lld:           :dll;:xdc;.   .,'.        //
//        .ldc,.  ,oxdlddoxl.         .lxoddldxo,  .,cdl.        //
//         .locc,..:llxxxdll,         ,lldxxxll:..,ccol.         //
//          .cocc:.:olddodlco,  ...  ,ocldoddco:.:ccoc.          //
//            .lxo:::::llodood,.:x:.,doodoll:::::oxl.            //
//             .:loxl:cc:okd:lxoodooxl:dko:cc:lxol:.             //
//               .,ooll;'ldo:cOkl:lkOc:odl';lloo,.               //
//                  'ckkcd0kl:clodolc:lk0dckkc'                  //
//                   .c0d;oOOxdxocoxdxOOo;d0c.                   //
//                     c0o;,:xxddxddxx:,;o0c                     //
//                     .okoc;,ldc:cdl,;coko.                     //
//                      .oxdo:;locol;:odxo.                      //
//                       ,xo,,;;clc;;,,ox,                       //
//                      .oxdo:;locol;:odxo.                      //
//                     .okoc;,ldc:cdl,;coko.                     //
//                     c0o;,:xxddxddxx:,;o0c                     //
//                   .c0d;oOOxdxocoxdxOOl;d0c.                   //
//                  'ckkcd0kl:clodolc:lk0ockkc.                  //
//               .,oolc;,ldo:cOkl:lOOc:odl';llol,.               //
//             .:ldxl:cc:oko:lxoodooxl:dkl:cc:lxol:.             //
//            'lxo:::::llodood,.:x:.;doodoll:::::oxl.            //
//          .cocc:.:olddodllo,  ...  ,ocldoddco:.:ccoc.          //
//         .loc:,..:llxxxdll,         ,lldxxxll:..,ccol.         //
//        .ldc,.  ,oxdlddoxl.         .lxoddldxo,  .,cdl.        //
//        .',.   .;cdx;;lld:           :dll;:xdc;.   .;'.        //
//               .llol.'lcl;           ;lcl'.lolc.               //
//               .:dd, .clc,           ,clc. ,xo:.               //
//                .,'   ':;.           .;:.   ',.                //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract Pldn is ERC721Creator {
    constructor() ERC721Creator("Paladin", "Pldn") {}
}
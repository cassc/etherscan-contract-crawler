// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JKTN - DANCE CHECKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                         ...'..                                      .:l:,.                     //
//                                     ..         ..,:clccldxkkx:.    .';clodol:'.                       .:lc'                    //
//                                 ..';:c:'    .,cdkOOOOOkxdoolc,..,lx0XNWWWWWWN0l.                        .,:c,.                 //
//                               .;cclodkko,.'cxkOOOOkxxxkkOOOOkx0KXNWWWWWWWWWWWWKc.                          'cc.                //
//                             .;cccoxOOOOxlc:;,:xOkxxk0XNWWWWWWWWWWWWWWWWWWWWWWWXl..                          ,dl.               //
//                           .,:lddxkOOOOOOOOkc,lxxk0XWWWWWWWWWWWWWWWWWWWWWWWWWWWN0kxdoc,..                    .lOd.              //
//                     .   .;ccdkOOOOOOOOOOOOOo:okKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKx:..                   .o0x,             //
//                   .,'..;cloxOOOOOOOOOOOOOkdldKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKo..',.                .cxx:.           //
//                 .',;;:clldkOOOOOOOOOOOkxxkOKNWWWXOx0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK:.:Ok;.               .ckxc.          //
//                .,;,,:clcdkdldkOOOOOkxxk0XNWWWWNx,. lXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXl.;ONd.                 ;xkc.         //
//               .,clc;;:ldkx'.ckOOOOxxOKNWWWWWWWk.   lXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK:.cKXl.                  .cko.        //
//              .;cllllcokOOo. :kOOkxkKNWWWWWWWWNd.   lNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNx''kXo'.                   .;xl.       //
//             .:lllllldkOOOo. ;kkxx0NWWWWWWWWWWNo    lNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNk,'dXN0d;.                   ..,.       //
//            .:lllllldOOOOOd. ,xxkXWWWWWWWWWWWWXl    lNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNx;,dXWWWWXx;.                            //
//          ..,cclllldkOOOOOd. 'lkXWWWWWWWWWWWWWX:    oNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKo,;kNWWWWWWNO;.                           //
//         ..':;,:lclxOOOOOOd' .oKWWWWWWWWWWWWWWK;    oNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx;'lKNWWWWWWWWXo..                          //
//        ..';c,.,ccdkOOOOOko';xXWWWWWWWWWWWWWWW0'    oNWWWWWWWWWWWWWWWWWWWWWWWWWWWXk:,cONWWWWWWWWWWXl.''.                        //
//        ..,cl:..cdkOOOOkd:;oKWWWWWWWWWWWWWWWWWk.    oNWWWWWWWWWWWWWWWWWWWWWWWWWWO:.;kXWWWWWWWWWWWNx'.oO;              ..        //
//       '.':llc'.ckOOOOkc.;ONWWWWWWWWWWWWWWWWWWx.   .oNWWWWWWWWWWWWWWWWWWWWWWWWWWO;.cKWWWWWWWWWWNKo''oXK:.            .'..       //
//      .,;;:lll;:xOOOOOx;c0WWWWWWWWWWWWWWWWWWNXo.    oNWWWWWWWWWWWWWWWWWWWWWWWWWWKc.;0WWWWWWWWN0d;'cOKkc.            .'''.       //
//     .';;;clllcdOOOOOkddKWWWWWWWWWWWWWWNKkoc;'.    .dNWWWWWWWWWWWWWWWWWWWWWWWWWWXc.;0WWWWNXOdc,.,cdo;.              .'''..      //
//     .,;;;cll::dOOOOOxd0WWWWWWWWWWWWWNk;.         .cKWWWWWWWWWWWWWWWWWWWWWWWWWWWO;.:0KOxoc;'..,clolc:.              ...';'      //
//    .,,;;;cll;,okOOOkoxNWWWWWWWWWWWWNx.      ..',ckXWWWWWWWWWWWWWWWWWWWWWWWWWWWNd..';::::;;coxOKKKKK0d'            .'..':,      //
//    cx;.,:lllc:lkOOOxlkWWWWWWWWWWWWWNd,';cldkOKXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO;...,x0xodk0KKKKKKKKK0l,,,'.     .,;:'.',.      //
//    dk;..;llllcdOOOOx:lXWWWWWWWWWWWWWNXNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO;....;lodOKKKKKKKKKKKKK0000Ol.   ':cc:'..;'      //
//    cx:,.,cllccdOOOkxloXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNk;.,loddx0KKKKKKKKKKKKKKKKKKKKx'..';:cc:;..:,      //
//    ,l;;'.;lll:cdoc;:oKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXd,.:kKKKKKKKKKKKKKKKKKKKKKKKKK0o:cooc;:c:;..;.      //
//    ,dc;,.,cc:;...  ,OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNk:.'lOKKKKKKKKKKKKKKKKKKKKKKKKK0dodddo:,:c:,''.       //
//    .,,;,.';'.     .lXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNOl'.:x0KKKKKKKKKKKKKKKKKKKKKKKKKOooddddc''::;''.        //
//    ...,;,,,.      .kWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXkc'.:d0KKKKKKKKKKKKKKK0KKKKKKKKKKKdcoddddc;:c:,''.        //
//     ..';;;;.      'kWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXko;.'cx0KKKKKKKKKK0kxol:,,dKKKKKKKKKKdlodddo:;:c,...         //
//     ...,;;;.      .oXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWWNNX0Oxdl;'':okKKKKKKKKKK0d;..    .cOKKKKKKKKKxclddddc.'::.            //
//      ...,,'.       'dKNWWNNWWWWWWWWWWWWWWWWWWWWWWWKdccllcc:,'...,cdOKKKKKKKKKKKK0l.  .;:ldOKKKKKKKKK0d:cddddl;.':,.            //
//      ......         .,clollONWWWWWWWWWWWWWWWWWWWNO:,;::::ccll,;okKKKKKKKKKKKKKKKk'  'xKKKKKKKKKKKKKkdoodddolc:',,.             //
//       .....               .cKWWWWWWWWWWWWWWWWWN0l,;d0KKKKKK0d:dO0KKKKKKKKKKKKKKKl  .l0KKKKKKKKKK0k:,cdddddl:c::,.              //
//        ....                .oXWWWWWWWWWWWWWWXOl,,oOKKKKKKOdodOKKKKKKKKKKKKKKKKKk'  ;OKKKKKKKKKKkd; .lddddlcccc;.               //
//        .....               ..c0NWWWWWWWWNXOd:,;oOKKKKKKOdldOKKKKKKKKKKKKKKKKKK0l  .oKKKKKKKKK0xoo, ,ddddlc:c:;.                //
//       .:l,...                .'cdkO0Okkdl;,,:x0KKKKKK0xcd0KKKKKKKKKKKKKKKKKKKKk'  ;OKKKKKKKKOxodo'.:ddoc;:c:'.                 //
//        ,OO:..                  ..........cxOKKKKKKKK0lcxKKKKKKKKKKKKKKKKKKKKKKl. .xKKKKKKK0xddddl.'lolc;,,;.                   //
//         ,k0d,.                        .;x0KKKKKKKKK0l:xKKKKKKKKKKKKKKKKKKKKKKk' .l0KKKK0kxddddddocllc:;,'..                    //
//          .ckkxc.                      'xKKKKKKKKKKKx;l0KKKKKKKKKKKKKKKKKKKKKKx::d0K0Okxddddddddddoc:,''..                      //
//            ;x00o.                     .,ok00KKKKKKKx,:OKKKKKKKKKKKKKKKKKKKKKKKKKKkdoclddddddddddl:,. ..                        //
//             'd00x'                       ..';;::oOK0o:codk0KKKKKKKKKKKKKKKKKKK0xc;cl::odddddool:'.                             //
//               ;xXKc                              .,:::,''l0KKKKKKKKKKKKKKKK0ko;.,lddl;:oddoc:,.                                //
//                .lKXo.                                   .oKKKKKKKK0kddxxxxddoc;:cc;'',;:cc:,.                                  //
//                 .l00c.                                   'codooloddoollooddol:'.    .','...                                    //
//                  .;ddl'.                                       .'ccc;;;;;,'.         .                                         //
//                    .:odl'                                                                                                      //
//    JKTN - @elements2dance - jktn.eth - Thanks @jackbutcher for the inspiration                                                 //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JKDC is ERC721Creator {
    constructor() ERC721Creator("JKTN - DANCE CHECKS", "JKDC") {}
}
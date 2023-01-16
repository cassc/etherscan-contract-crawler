// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chica Desconocida
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    . . . . . . . . ... . .............................................................................     //
//                       .   . . . .       .             .     .       . . . . . . . . . . . . . . . . .      //
//    . . . . . . . . . . . . . . . .   ...  ..  ...  ..    ... . ... ...................................     //
//       . . . . . . . . . . . . . . .DDDDC  DD. .DD .DD   DDDD. .DDDC ...................................    //
//    . . . . . . . . . . . . . . .  DD.     DD   DD  DD  DD. .  .DDDD  .................................     //
//       . . . . . . . . . . . . .  .DD      DDDDDDD  DD  DD     DDDDDC  .................................    //
//      . . . . . . . . . . . . . . .DD      DD...DD  DD  DD     DDDCDD.  ...............................     //
//                   . . . . . . .   DDC ..  DD. .DD  DD. DD  .. DD  .DD . ......... .....................    //
//                                    CDDDD  CD.  DD  CD. .DDDD. DC   DD.   . .   .     .....   .........     //
//           .CDDC     . ...     ..                              ..       ...  ..  ...   . . ... .........    //
//           CDD.DDD  CDDDDDC .DDDD.   .DDD.  CDDDD   DD  DD.  .DDDDC   CDDDD .DD  DDDDD. . .DDD. .......     //
//           .DD  .DD .D.     CDC     CDD    CDD .DD  DDD DD.  DD. DDC CDD     DD  DD. DD.  DDDDD  .......    //
//            DD   DD .DDDD.  .DD    .DD     DD   DD. DDDDDD. .DD  .DD DD.     DD. .DC CDC  DDDDD.  .....     //
//            DD   DD .DD ..   .CDD. CDD     DD   DD  DDDDDD. .DD  CDD CDD     DDC .DD .DD .DD..DD   .....    //
//            DD   DD .DD        .DD  DD..C  DD  DD.  DD .DD. .DD .DD   DDC.DD .DD  DD.DD. DD.  DDD .....     //
//            DDDDDD. .DDDDD.  DDDD.  .CDDD. .DDDD.   DD  CD.  .DDDC     .DDC. .DC  DDDD.  DD.   DD. .....    //
//             ...        .                                           .                       .     .....     //
//                                                  ......           . . . . . . . .   . . . ... . .......    //
//                               .C              .DDDDDDDDDD.     . . . . . . . . .   . .................     //
//                               DD            .DDDDDD.DDDDDDD.  . . . . . . .         . . ...............    //
//                              DDC           CDDDDDD. DDDDDDDDC  . . . . .     ..CDD.  . . . ...........     //
//                             .DD.          CDDDDDDC   DDDDDDDD.  . . . .   CDDDDDD.. . . . . . .........    //
//                       ..   .DDDD          DDDDDDC     .DDDDDDD   . . .   DD. DD.   . . . . . . . .....     //
//                       DDDDDD  DD.        .DDDDC          .DDDD    . .   DD  CD.         . . . . . . ...    //
//                          CD.  DDD.       .DD           . .DDDD   . .   CD.   DD.         . . . . . ...     //
//                          .DDDD..CDC       DD.DDDDD. .DDDDC.DDD    . .  DD     CDDDD.CDD.  . . . . . . .    //
//                          DDD              DDD DD DD.CDC.D. DDC     .   .DD        .DDDC  . . . . . . .     //
//                         DDD               DDD DDDDC   CDDDDDD.          .DDC. . .CDDC   . . . . . . . .    //
//                        CDD                .DDDD   .C..   .DDD             .CDDDDDC.    . . . . . . . .     //
//                        ..                 .DDDDC   .D.  DDDDD                         . . . . . . . .      //
//                                            DDDDDDDDDDDDDDDDDD                        . .     .   . . .     //
//                                            CDDDDDDD.   DDDDDD                           .CC       . .      //
//                ..    C.                     DDDDDDD     DDDDDC.                    ..    C.    CD. . .     //
//          ..    DDDD  DDDC                 .DDDD..DD.   .DC  .CDDC                  CD.  .CDDD.  .          //
//         .DDDDD  DDDD.DDDDD              .DDC      .DDCDD.      .DDC                    DDC ..DD.   .       //
//           DD..DDDDC.DDD  DD           .DDC          .CC          .DDC             ..  DD      DD  CDC      //
//           .DC  DDDD DDD. CDC        .DDC     .              .DD.   .DDC           CD  DD      DD   .       //
//           DDC   DD. .DD  CDD      CDD.    .DDDC             DDDDD.   .DDD             CDD...DDD            //
//           ..     .   C.  .C.    CDD.    .DDC.DD             DD  CDD.   .DDD.            .DDD.   DD   .     //
//                               DDD.    .DDC   DD             DD    CDD.    DDD.      .DD   .D.   ..         //
//                             DDD.    .DDC     DD             DD      .DDC    CDDC           C               //
//                           DDD     CDDC       DD             DD        .DD.    CDDC                         //
//                        .DDD     .DDC         DD             DD.         .DDC    .DDC                       //
//                       DDD     CDD.          .DD             .DC           CDD.    .DDD                     //
//                    .DDD     CDD.            .DD              DD             .DDC    .DDC                   //
//                  .DDD     DDD.              DD.              DD               CDD.     DDD.                //
//    .           .DD.     DDD.                DD               CD.                CDDC  .DD.DDDC.            //
//               DDDD    DDD                  .DD               .DD      .CDDD.      CDDDDDD.  .DDDD.         //
//    . .     CDD. .DDDDDC.      CC           DD.                DD     CDD DDC        ..  .CDDDDDDD.         //
//       .  CDD   DDC.CC        .DD           DD                 DD.    DD.DDD.                               //
//    . .  .DDCCDDC              DD          DD.                 .DD     .C.CDD                               //
//       .   .CC             CDDDDDDDD.     .DD                   DD         DDD.                             //
//    . . .                  ....DD         DD                    DD                                          //
//       . . .   . . . . .       DD        .DD.... .     . ....CDDDDD                                         //
//    . . . . . . . .            CD        DDDDDDDDDDDDDDDDDDDDDD..DD                                         //
//       . . . . . .                      .DD  ................... .DD                                        //
//    . . . . . .     ..CCC..             DD. ..................... DDD.                                      //
//    .. . . . .    CDDDDCDDD. . . . .   DDD.......... . . ......CDDDDD.            CDDDDDDD                  //
//    . . . . .   CDD.          . . . .  .CDDDDDDDDDDDDDDDDDDDDDDD.DD.                  DDD                   //
//    .... . . . CDD  .DDDDD.    . . .      .DD  . . DDD..DDC       DD                 DDDDC                  //
//    . ....... .DD  DDD.. .DD  . . . . .    DD      DD   .DD       DD                     DD                 //
//    ........  .DD  .DDDC  DD.  . . . . .   DD      DD    DD       DD                    .DD                 //
//    . .......  DDD       DDD  . . . . . .  DD      DD    DD       DD               .CDDDD.                  //
//    ..........  .DDDCCDDDD.  . . . . . .   DD      DD    DD       DD               CCC.                     //
//    . .........   ..CCC.    . . . . . . .  DD      DD    DD.      DD                                        //
//    ............         . . . . . . . .   DD      DD    CDC      DD                                        //
//    . ............. . . . ... . . . . . .  DD     .DC    .DD      DD                                        //
//    ........................ .       . .   DD     .D.    .DD      DD                                        //
//    .......................   ..CCC   . .  DD     DD. .   DD      DD                                        //
//    .........................DDDDCDD.  .   DD     DD.  .  DD      DD   .     .DD.       .DC                 //
//    ....................... CDC   DD. ...  DD     DD. .   DD.     DD.   . .   CD.       .DC                 //
//    ........................     DD. ...   DD     DD   .  .D.     DD.  . . .                                //
//    ........................... .DD   ... .DD     DD  . . .DD     DD.   . .                                 //
//    ............................ DDC ....  DD     DD   .   DD     DD.  . .         .                        //
//    ............................  .. ....  DD    .DD  . .  DD     DD. . .     .C      .                     //
//    .............................  ......  DD    CDC . .   DD     DD.  .  CD. DD.      . .                  //
//    ............................. CDC ... .DD    CD.  ...  DD.    CD. . .  .DDDDDDD   . . . .               //
//    .............................. . ....  DD    DD. ..... CDC    CD.  .  .DDDDDDDDD   . . . . .            //
//    ..................................... .DD    DD. ....  .DD    CDC . .   DDDDD     . . . . . . .         //
//    .......................... . ........  DD    DD. ..... .DD    .DC  .  .DDDDDDD.  . . . . . . . . .      //
//    ..........................C.......... .DD    DD ......  DD    .DC . . ..  DD DDD  . . . . . . . . .     //
//    ........................CDDDD........ .DD    DD  .....  DD    .DC  ...        .. . . . . . . . . .      //
//    .........................   ......... .DD   .DD ....... DD.   .DD ... . .   .   . . . . . . . . . .     //
//    ..................................... .DD   .DC ......  .D.    DD  ......... . . . . . . . . . . .      //
//    ..................................... .DD   CDC ....... .DD    DD ............. . . . . . . . . . .     //
//    ..................................... .DD   DD. ....... .DD    DD  ............... . . . . . . . .      //
//    ..................................... .DD   DD. ....... .DD    DD   ................. . . . . . . .     //
//    ....................................  DDD   DD ......... DD.   DD.   ................... . . . . .      //
//    .................................    DDDDDDDDD  ....... .DDDDDDDDD.   ..................... . . . .     //
//    ................................ ..DDDDDDDDDDD ........ .DDDDDDDDDDDD.   ..................... . . .    //
//    ............................... .DDDDDDDDDDDD.......... .DDDDDDDDDDDDDD  ..........................     //
//    ................................DDDDDDDDDDC. ........... ..CDDDDDDDDDDDD ...........................    //
//    ............................... DDDDDDDD.   .............       DDDDDDDC...........................     //
//    ................................ .....   .....................     . .  ............................    //
//    . ...............................     . .........................     . ................... . . . .     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CD is ERC721Creator {
    constructor() ERC721Creator("Chica Desconocida", "CD") {}
}
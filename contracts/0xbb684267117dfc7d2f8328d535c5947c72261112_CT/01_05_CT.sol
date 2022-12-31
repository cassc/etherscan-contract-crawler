// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoTron
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                 __xxxxxxxxxxxxxxxx___.                             //
//                            _gxXXXXXXXXXXXXXXXXXXXXXXXX!x_                          //
//                       __x!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!x_                     //
//                    ,gXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx_                  //
//                  ,gXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!_                //
//                _!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!.              //
//              gXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXs             //
//            ,!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!.           //
//           g!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!           //
//          iXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!          //
//         ,XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx         //
//         !XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx        //
//       ,XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx       //
//       !XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXi      //
//      dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX      //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!     //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!     //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!    //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!    //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!    //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!    //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//      !XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//       XXXXXXXXXXXXXXXXXXXf~~~VXXXXXXXXXXXXXXXXXXXXXXXXXXvvvvvvvvXXXXXXXXXXXXXX!    //
//       !XXXXXXXXXXXXXXXf`       'XXXXXXXXXXXXXXXXXXXXXf`          '~XXXXXXXXXXP     //
//        vXXXXXXXXXXXX!            !XXXXXXXXXXXXXXXXXX!              !XXXXXXXXX      //
//         XXXXXXXXXXv`              'VXXXXXXXXXXXXXXX                !XXXXXXXX!      //
//         !XXXXXXXXX.                 YXXXXXXXXXXXXX!                XXXXXXXXX       //
//          XXXXXXXXX!                 ,XXXXXXXXXXXXXX                VXXXXXXX!       //
//          'XXXXXXXX!                ,!XXXX ~~XXXXXXX               iXXXXXX~         //
//           'XXXXXXXX               ,XXXXXX   XXXXXXXX!             xXXXXXX!         //
//            !XXXXXXX!xxxxxxs______xXXXXXXX   'YXXXXXX!          ,xXXXXXXXX          //
//             YXXXXXXXXXXXXXXXXXXXXXXXXXXX`    VXXXXXXX!s. __gxx!XXXXXXXXXP          //
//              XXXXXXXXXXXXXXXXXXXXXXXXXX!      'XXXXXXXXXXXXXXXXXXXXXXXXX!          //
//              XXXXXXXXXXXXXXXXXXXXXXXXXP        'YXXXXXXXXXXXXXXXXXXXXXXX!          //
//              XXXXXXXXXXXXXXXXXXXXXXXX!     i    !XXXXXXXXXXXXXXXXXXXXXXXX          //
//              XXXXXXXXXXXXXXXXXXXXXXXX!     XX   !XXXXXXXXXXXXXXXXXXXXXXXX          //
//              XXXXXXXXXXXXXXXXXXXXXXXXx_   iXX_,_dXXXXXXXXXXXXXXXXXXXXXXXX          //
//              XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXP          //
//              XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!          //
//               ~vXvvvvXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXf           //
//                        'VXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXvvvvvv~             //
//                          'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX~                      //
//                      _    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXv`                       //
//                     -XX!  !XXXXXXX~XXXXXXXXXXXXXXXXXXXXXX~   Xxi                   //
//                      YXX  '~ XXXXX XXXXXXXXXXXXXXXXXXXX`     iXX`                  //
//                      !XX!    !XXX` XXXXXXXXXXXXXXXXXXXX      !XX                   //
//                      !XXX    '~Vf  YXXXXXXXXXXXXXP YXXX     !XXX                   //
//                      !XXX  ,_      !XXP YXXXfXXXX!  XXX     XXXV                   //
//                      !XXX !XX           'XXP 'YXX!       ,.!XXX!                   //
//                      !XXXi!XP  XX.                  ,_  !XXXXXX!                   //
//                      iXXXx X!  XX! !Xx.  ,.     xs.,XXi !XXXXXXf                   //
//                       XXXXXXXXXXXXXXXXX! _!XXx  dXXXXXXX.iXXXXXX                   //
//                       VXXXXXXXXXXXXXXXXXXXXXXXxxXXXXXXXXXXXXXXX!                   //
//                       YXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXV                    //
//                        'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX!                    //
//                        'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXf                      //
//                           VXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXf                       //
//                             VXXXXXXXXXXXXXXXXXXXXXXXXXXXXv`                        //
//                              ~vXXXXXXXXXXXXXXXXXXXXXXXf`                           //
//                                  ~vXXXXXXXXXXXXXXXXv~                              //
//                                     '~VvXXXXXXXV~~                                 //
//                                           ~~                                       //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract CT is ERC721Creator {
    constructor() ERC721Creator("CryptoTron", "CT") {}
}
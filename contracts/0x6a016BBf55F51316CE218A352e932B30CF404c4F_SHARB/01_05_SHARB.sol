// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sharbi Meme 2.0 - Limited Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                 **.                                            //
//                                                 **. ..                        /*. ,*, .                                        //
//                                                /..,*,  .    ..      .,....,*/,. ../*,.                                         //
//                                              */../((/,. .....*. ....,,..........,//**.                                         //
//                                             ((,./###*,,..,,*/..........**,...   *(/*,.                                         //
//                                           .((,.,#%%#*,,,*/#(,,,,.,,......,*,....  .*,..                                        //
//                                          ./(*,.,%%%(/***(#****,,,,,,,,..,.,*,,...   . .                                        //
//                                       .,,///*.,/%%(//(##/***********,,,,.,,*/*,,..    .                                        //
//                                  .. ..../((*,/*//(*/(#******//////**/***,,,,//*,,.. ....                                       //
//                              ..       .,/(*/,,,***/*****//////(((/(//*,,,***/(**,,..*,...                                      //
//                            .         .,*((///((/******/*/////((##/,,***,,..//(/*..  ,*,. .                                     //
//                          .         ..,*/(###**,,,***//////(((*..,*******,.*/*#((,. /&,/, .                                     //
//                        ..          ..,*(#(/*****//*(((#((///(#&&&%&@&%&%/*/,..,.,*&&/.  .                                      //
//                       .            ...,/#(//((*,......... ...,,..,(%%%###(/,.                                                  //
//                                     ..,/#%(*,..........       .,,,,,,..,///*,,.....                                            //
//                    .                 .,*(#*,..............        . ...,**//*,.....,,.   .                                     //
//                   .                  ..,/(/,....................    ...,,***,..  .,/(((*..                                     //
//                  ......                .,,/*,............,,,,,,,.......,,**,....../&&&&@%%#                                    //
//                 ..........               .,/*,..........,,,****,.....*..,,.,.....,*(%%#&&%/.                                   //
//                 ..............            .,,*,,.........,,,*,,,,,,.,...../.,,..,,*//##%(.                                     //
//                 ,,,,,,,,,,.,....           ...,***........,,,,*,,**(%&&%*,*****//(#((%@%#,.                                    //
//                .,,,,,,,,,,,,,,......          ....,*,,.....,,,,************/////(((#(/.    ..                                  //
//                .*************,,,,,.....          .....,*,,..,.,,**/////////***...... ..       ...                              //
//                .*****************,,,,,......         .....,*,,,,,,,********,..      ...          ....                          //
//                .***////////////******,*,,.......      .......,*,,,,,,,,*,,,...     ......           ....                       //
//                 ,**/////(((##(((////*****,,,,,...... ..........,,,,,,,,,,,....     .,,...             ....                     //
//                 .**/////(((((##(####((///****,,,,,,...............,,,,,.............,.....             ...,.                   //
//                  ,*///////((((((##########(//****,,,,,,,...........................**,,....             ...,.                  //
//                   ,//////////((//(#((((#####%%#(//*****,,,,,,,,,............  ...,,///*,.......          ...,.                 //
//                    ,*//////(////////((//((/(((#######(///***,,,,,,,,,,,.........,/%#((//*,,.. ..         ...,,.                //
//                     .*//////////**//***//*/***//(((#####(///******,,,,,,,......,/%##(%(//**,,,...        ....,.                //
//                       .*//////////***/*,*/********//(((####((/*******,,,,,*,,,,,(&%%#(/(&(/**,,,,,,.........,,,                //
//                          *//////*///**,**,**,***,,***///(#(((((/*/****,,,,,**,,,,/%###%#/*%%#((/*,,.,,......,,.                //
//                            (((/(///*///*,*,,*,,**,,,*****/((/((////*****,,,...,.,,*(%#(/*%*##(((((/**,,,,..,,,.                //
//                           (((#(((///**/*/***,**,**,,,*,,***(//////*/****,/*.......,,/%/#/**%,(/**///**,,,,,,,.                 //
//                         ./(((#/((/((/(/************,,**,****/////////***,...........,*(%//*,*#/,***/***,,,,,.                  //
//                         //(///////*/*///////*****************/*////////%%%%#/,.   ....,*(/(*,,%/*,******,,.                    //
//                        ,///(*/((**/*/,*(((///******************///////#(#(#%%%%##/. .....,#(*,,#(*,****,,.                     //
//                        ,////****////////*/**//////**************////((*,/*(#######((,.....,#/*,,(/*,.**,                       //
//                        */(*(/****//*,*/*/,*,.**////////*******////(#/***,,*#%(//(#((/*......((*,,#/*,,.                        //
//                          //,,**/,//,.*//,,,.*,,,,.*/**//*//////((%#(#/,***.,/###(((///.......//,.,(/*.                         //
//                             **,*(,**,.*,/,.,,..**.,,....,.,,,,*((%%(/,*,**...*(/////***....,,((*,*.                            //
//                                 ,**,**,./***/,*,*,*,.**......,.*(#%(/**/,.*.../////****,,,,,,(/                                //
//                                     ,*.,**(.***,*/,.*,..,.,.,.,,/##(//(*(,.,.../////***,**.                                    //
//                                           */,/*/*,,*,,,.,,,.,...*/#//***,/*.,,..////*                                          //
//                                                   **/,,**,,**.,,,*(#(*/,**,*.                                                  //
//                                                                                                                                //
//                ******** **      **     **     *******   ******   **       ****     ** ******** **********                      //
//                 **////// /**     /**    ****   /**////** /*////** /**      /**/**   /**/**///// /////**///                     //
//                /**       /**     /**   **//**  /**   /** /*   /** /**      /**//**  /**/**          /**                        //
//                /*********/**********  **  //** /*******  /******  /**      /** //** /**/*******     /**                        //
//                ////////**/**//////** **********/**///**  /*//// **/**      /**  //**/**/**////      /**                        //
//                       /**/**     /**/**//////**/**  //** /*    /**/**      /**   //****/**          /**                        //
//                 ******** /**     /**/**     /**/**   //**/******* /**      /**    //***/**          /**                        //
//                ////////  //      // //      // //     // ///////  //       //      /// //           //                         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHARB is ERC721Creator {
    constructor() ERC721Creator("Sharbi Meme 2.0 - Limited Edition", "SHARB") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manfred Teh Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    kd:.                                                                                                                                              .:dO    //
//    NWN0xc,.                                                                                                                                      .'cx0NWW    //
//    XWMMWNXOo;.                                                                                                                                .;oOXNWMMWN    //
//    XWMMMMMMWN0dc'.                                                                                                                        .':d0NWMMMMMMMN    //
//    XWMMMMMMMMMMWKkl,.                                                                                                                  .,lkKNMMMMMMMMMMMN    //
//    XWMMMMMMMMMMMMMWX0d:'.                                                                                                          ..:d0XWMMMMMMMMMMMMMMN    //
//    XWMMMMMMMMMMMMMMMMWNKxc,.                                                                                                    .,cxKNWMMMMMMMMMMMMMMMMMN    //
//    XWMMMMMMMMMMMMMMMMMMMMWXOo;..                                                                                            ..;oOXWMMMMMMMMMMMMMMMMMMMMMN    //
//    XWMMMMMMMMMMMMMMMMMMMMMMMWNKxc'.                                                                                      .'cxKNWMMMMMMMMMMMMMMMMMMMMMMMMN    //
//    XWMMMMMMMMMMMMMMMMMMMMMMMMMMWWXOo;.                                                                                .;okXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMN    //
//    XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0d:'.                                                                        .':d0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN    //
//    XWMMMMMMMMMMNXNWMMMMMMMMMMMMMMMMMMMWNKkl,.                                                                  .,lkKNWMMMMMMMMMMMMMMMMMMWKOOXMMMMMMMMMMMN    //
//    XWMMMMMMMMMWOc:oOXWMMMMMMMMMMMMMMMMMMMMWXOd:..                                                          ..:dOXWMMMMMMMMMMMMMMMMMMMNKkl'.;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'  .,lkKNWMMMMMMMMMMMMMMMMMMMWNKxc'.                                                    .'cxKNWMMMMMMMMMMMMMMMMMMWX0dc'.   ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'     .':dOXWMMMMMMMMMMMMMMMMMMMMNXOo;.                                              .;oOXNMMMMMMMMMMMMMMMMMMMWKOo;.       ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'         .,lkKWMMMMMMMMMMMMMMMMMMMMWN0xc'.                                      .'cx0NWMMMMMMMMMMMMMMMMMMWNKxc'.          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'            .'cd0XWMMMMMMMMMMMMMMMMMMMMNKkl,.                                .,lkKNMMMMMMMMMMMMMMMMMMMWX0d:..             ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                .;lkKNMMMMMMMMMMMMMMMMMMMMWX0d:'.                        .':d0XWMMMMMMMMMMMMMMMMMMMNKkl,.                 ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                   .'cx0NWMMMMMMMMMMMMMMMMMMMWNKkl,.                  .,lkKNWMMMMMMMMMMMMMMMMMMWN0xc'.                    ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                       .;okKNMMMMMMMMMMMMMMMMMMMMWXOo;.            .:oOXWMMMMMMMMMMMMMMMMMMMWXOo;..                       ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                          .'cx0NWMMMMMMMMMMMMMMMMMMMWN0xc,.    .,cx0NWMMMMMMMMMMMMMMMMMMWNKkl,.                           ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                              .;oOXWMMMMMMMMMMMMMMMMMMMMWXkoccokXWWMMMMMMMMMMMMMMMMMMWN0d:'.                              ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                 .,cxKNWMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMWWXOo;.                                  ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                    ..;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xc,.                                     ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                        .,lkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0d:.                                         ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                           ..:d0XWMMMMMMMMMMMMMMMMMMMMMMNKOo;.                                            ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                               .,lkKNWMMMMMMMMMMMMMMWN0xc'.                                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                  ..:dOXWMMMMMMMMWXOd:.                                                   ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                      .,lkKNWWNKkl,.                                                      ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                         .'cllc'.                                                         ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                                                                                                          ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                 .                                                                                        ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                ,od:.                                                .,ldc.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                ;OWN0xc'.                                        ..;oOXWXd.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                ;OWMMWWXOo:.                                  .,cxKNWMMWXo.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                ;OWMMMMMMWN0xc'.                          ..;okXWMMMMMMWXo.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                ;OWMMMMMMMMMMNKko;.                    .'cx0NWMMMMMMMMMMXo.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                ;OWMMMMMMMMMMMMMWN0xc'.             .;oOXWWMMMMMMMMMMMMWXo.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                               .:OWMMMMMMMMMMMMMMMMMWKko;.      .'cd0NWMMMMMMMMMMMMMMMMMXo.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                'oKNWMMMMMMMMMMMMMMMMMMWX0d:,';lkKNWMMMMMMMMMMMMMMMMMMWXx;.                               ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                 ..:d0NWMMMMMMMMMMMMMMMMMMWNNNNWMMMMMMMMMMMMMMMMMMMWKkl,.                                 ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                     .;oOXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xc'.                                    ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                        .,cxKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo;.                                        ;0MMMMMMMMMMMN    //
//    XWMMMMMMMMMWO'                                           ..:dOXWMMMMMMMMMMMMMMMMMMMMMMMNKkl,.                                           ;0MMMMMMMMMMWW    //
//    XWMMMMMMMMMWO'                                               .;okXWWMMMMMMMMMMMMMMMWN0x:'.                                              ;0MMMMMMMMMMWW    //
//    XWMMMMMMMMMWO'                                                  .'lONMMMMMMMMMMMMWKd;.                                                  ;0MMMMMMMMMMMW    //
//    x0NMMMMMMMMWO'                                                    .:OWMMMMMMMMMMMXd.                                                    ;0MMMMMMMMMNKk    //
//    .':d0XWMMMMWO'                                                     ;OWMMMMMMMMMMMXo.                                                    ;0MMMMMWX0d:'.    //
//        .,lkKNWWO'                                                     :OWMMMMMMMMMMMXo.                                                    ;0MMNKkl,.        //
//           .'cx0k'                                                     :OWMMMMMMMMMMMXo.                                                    ,k0xc..           //
//              ....                                                     :OWMMMMMMMMMMMXo.                                                    ...               //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                       :OWMMMMMMMMMMMXo.                                                                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MTEHE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
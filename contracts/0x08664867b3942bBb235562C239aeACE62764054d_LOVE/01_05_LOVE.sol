// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVE OR LUST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ,,,,,,,,,,,,,,,,*,,,*,***,,,,,,*,,,,,*,*,,,,,,,,,,,,,,,,......,..,,.,.,,,,,***///(//////////////*/(/    //
//    ,*,***,,,,,,,,*,*,,*,**,,,,,,,,,,*,,,,,,,*,,,,,,,,,,,,.,,..,.....,,.,,,,*,**///////////(///(//*/////    //
//    ,**********,,,,,,,,,,*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,,,,,...,,,,,,*,***///////(///////(/////(//    //
//    ***,,,,,,,,,*,,,,*,,,*,,,,,,,,,*,,,,,,,,,,*,,,,,,,,,,,,,.,.,...,,,,,,,,***////////////(/(/(//,,.  */    //
//    ****,,,,*///*,..   ,,,,*,,,,,,,,,,,,,,,,,,*,,,,,,,,,,,,,.,...,.,,,,,,,,,**///////////////(/(/*,,....    //
//    *,,*(((((((/*,...    ,,,,,,,,*,,,,,,,,,,,,,,,,,,,,,,,,,.,. ....,,,,,,,..**/(//,,,..    ((((((/((///*    //
//    ((((((((((/**,.,..    ,,,,,,,,,,*,,,,,,,,,,,,,,,,,*(//////((/(((/(/(//((#(#(###(//**,...  ./((((((((    //
//    (((((((((/**,..,,..    .,,,*,,,,,*,,,,,,,,,,,,,,,*/*/(/////////////////(//((((((((((/**,,,..  .(((((    //
//    /(((/(((/*,.   /((,.  .  ,,****,,*****,,**,,,,,,,,*((/((///////////*/////(/((((((((#(((//***,,.. .,(    //
//    ((((((///*.  #%##(*.  /*. .,/****************,,,,,,,//(((((((((//((/(////////(//((((#((#(((/////***,    //
//    (#(((((/*,. %%##(/,    **. ,*,..,**//*//**************,(#((((((///((((((((/(////(///(((((#(###(##(#(    //
//    (#(((////,. %#(*,,,.   ../*//**,,*.. .  .*///**//*******,*///,,./*(//**/*/////////(////#((((#(#(((((    //
//    ##(((////*.  ,,*/(((((#((%##( /*,.   ,...,..((///*///*/*****/(/.,.((,**/*****/////(//////(((((((((((    //
//    ###((((/(/*/((((((((((((#%%%/#(*,*,,..***,.  .(((/(/(////*****/*( ,*//****///***////////(/(((((((((/    //
//    (###(#(((#%((((((((#(((##%%%#((/*.       */*,. /#(((((////////*..,.(*/*/*////////**//(//////(/((((((    //
//    ..,(((###(#((#((((##(####%%###((*,,.,,,,. *(/*.  #####(#(((//(//.. *,/***//////////*///(///(///(((((    //
//    *///(#(#(((((####(#(#(#(##%%##((//*/((((((###(/,  /#((###((////*,    ,**//*////*//*///**/////(//(((#    //
//    ///(/(######(##(((##((((######(**(######((/(##((*.  (((((((((///*.   */////////////////*////(//(((((    //
//    *///((#(###(##(####(##((##%%%//#######(######%##((*  *(((((////(//,.*,////*//////*//*//////(/(/////(    //
//    ///(((((##((###((((#((((#####//##%#########%%##,##((*  ***,,,,,,..,.*,,***///*///*/////*////*(((((((    //
//    ((((((((((((##(((#(((((#((##%*(#######(((/#%%%%%(/**/(##########((/,, *....  *////*///////*///*(((((    //
//    //(/(((/((((((((#(##((((#####(*%%%#%%%%%#%%%((((#(####(###((####(#((#/*,/..... *///*/*/////***(#((((    //
//    (/(((((((((((((###((((((((((#(*%%%%#%####((##########%###%######%####(#/.**   .****/////**///#((##((    //
//    (//(((((((((((((##(##((((((##(*,%%%%%%%(####%##%%#########%#%######(#*((*.....***//*/*******(((####(    //
//    //(/((((((((((#((((((((((((((##(*%%%%(##%#(################%#%%%%%##(##(//,*,.,*/**/**/**/*/((#(####    //
//    ((((((((((((((((((((((((((((((###((#(##%###%%#%#%%#%%%%%&&&%%%%#/##(((,..,//.,, ,****/*****(######%#    //
//    (((((((((/(/((/((((((((((((((((################%#%#%##%###%%%%%###(//,,/ .,*,/, ./***/****((((####(#    //
//    (((/((((//*/****/*/(//((((((((((##(##############%%%%%%%%%%%%%%%%%##(((#(, .(/*..,/*/*//*/((((((###(    //
//    ((((/**/***/***/*//(((((((((((((((#(###(###############(########(#(/((##(,,,,*.,  ******/((((((((((#    //
//    ///********////((((((((((((((((((((((((#(#(###(#(#####((#####((/((((((*,../ ..,. , .*//*(((((((((#((    //
//    ****/*/*//((((((((((((((((((((((((((###(#(#################(((//,,,.,/(//**/(. ....   **((((((((((#(    //
//    *////(((((((((((((((((((((((((((((((((((((#(#(######((#(((((((//*,,,,.........,,......../(/((((((((#    //
//    ((//((/(((((((/((((((((((((((((((((((((((((((((((#((((((((///*****,*,*,,,,,,,*,,,,..... .///((((((((    //
//    ((((((((((((((((((((((((((((((((((((((((((((((##((((#((#((((((//*/**,,,,,****,,*,,,....  .///(/(((((    //
//    /(((((/((((((((((((((((((((((((((((((((((((((((((((((((#(((#(((/(////(//******,***,,..      //(//(/(    //
//    ((((((((/(((//(((((((((((((((((((((((#((##(((((((((#(((#((((#((((((((//((((//*****,,,.        *(((//    //
//    (((((((((/((/((((((((((/(((((((((((((((((((((((((((((((#(((##((((((((((((/((//******,..         ,///    //
//    (((((/((((((((/(((((((((((((((((((((((((((((((((#(((((((((#((((((((((((((((((///,*,,,...          //    //
//    /((/((((((((/(((((((((((((((((((#((((((((((((((((((((((((((((((((#(#((((((/(((/*/*,,,,...        **/    //
//    (/((//((((((/((((((((((((/((((((((((((((((((((#(((#(((((#(((((((((((((((((/(////***,,,.... . ...*///    //
//    /((((/((((((((/((/(((/((((((((((((((((((((((((((((((((((((#((((((((((((((/////*******,,,,... (/.**//    //
//    ((((//(((((((((((((/((/(/(((((((((((((((((((((/(((((((((((/(((((((((((((////*/***,,,,*,,,. ****/////    //
//    (((///(((/(((((((/(((((((((((((((((((((/(((((((((((((((((((((((/(//(///////*,,,,,.,,*,.. ,//////////    //
//    //((((/(((((((/((/(((((((((((((((((((((((((((((((((((((((((((/(//////***,,,,.,,,*,,.,,.,/////////(//    //
//    ((/(((((/(///((((//(((((((((((/((((((((((((((((((/(/((((((((////*/**,,,,,,,,***,,,,,,////////*//////    //
//    (//(///(/(((((/////((((/((((((/((/(((((/((/((((((/(((((////******,*,,,,*,,****,,.,/////////////////*    //
//    ((///((/(/((((((((((((/(((((((/(((/(((((/(/(((/((////////*******,**,*******,,.*//////////////////(//    //
//    ((//((((((((((((((((/((((((((((/(((/(((///((((////////******,,,**,**,,,,,,//////////////////////*///    //
//    (((((((//((((((((((/((((((((((((((((//((/(////////****,,,,,*,,,,.,,..,//////////////*///*///////////    //
//    (((/(((/((((((((((((((/((((((((((((//((//////****,,*,*,,,.........*/////*//////////////////*//////*/    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LOVE is ERC721Creator {
    constructor() ERC721Creator("LOVE OR LUST", "LOVE") {}
}
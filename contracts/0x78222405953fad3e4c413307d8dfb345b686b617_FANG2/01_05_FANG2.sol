// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cryptofangs Whispers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//         ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░███████╗░█████╗░███╗░░██╗░██████╗░░██████╗       //
//         ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗░██║██╔════╝░██╔════╝       //
//         ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║█████╗░░███████║██╔██╗██║██║░░██╗░╚█████╗░       //
//         ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██╔══╝░░██╔══██║██║╚████║██║░░╚██╗░╚═══██╗       //
//         ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██║░░░░░██║░░██║██║░╚███║╚██████╔╝██████╔╝       //
//        ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░╚═════╝░        //
//    //**********////////////////*****////////////////////*************/////***********//////////////////    //
//    ////////*/////////////////////////////////////////////////////////////////////////////////////*///*/    //
//    //////////////////////////////////////////////((////////////////////////////////////////////////////    //
//    (((//*///////(///////////////////////////////////**//////////***////////////////////////////////////    //
//    ///((////////((//////////////(/////////**///////////////*////////////////////////////////////(//////    //
//    (((((///**////////////////////////////////////////////**///////////////////////(////////////////////    //
//    (((((/(//*//////////////////////////((///////////////////////////////(//////////////////////////////    //
//    (((//////*****////////(((//////////////((((((((////////(/(((///(///////(///(///////////(//((((//(((/    //
//    (//(//////////////(///////////////////((//((/((((((((//(((//////////(//////////////(((///((/////////    //
//    /(((((((((/((///////////((((((//(///////////(((((((((((((((//////////////(((//////(///////////////((    //
//    /(/((((((//(/*//////////////((((((((////(((/.,,*,*,*((((((((((((((((/((((///////////((/((((////////(    //
//    /((//((/*///((((((////////////((((((((((((//*(((((*//(((((((/(((////((///////////////((((((///*****/    //
//    #((((((((((//(((((((//////(((((((((///((((*/##/,/((((((((((((/((((((//((////((((///(((////********//    //
//    (((###(#(((((#((((((/(//((((((((/(((////(*(*(,,..,((#*((((((/((((., . *,(((/(///////((((////////////    //
//    ((((((((((((###(((((//((((((//*/(((((((((**#%*,**,%&(*////(/((////(/*((./(((//(((((((((/////////////    //
//    (((((////(((((((((((((/(/     ..,((((((((*/(&&&&&&&&%**((//////////((*  *////(((((///((/////((((////    //
//    ((((((////((((/((((((((/.,/(((/*///,/##%%#/(%%%%%&%%%#,,*////////(//(%%%%(///(((((/((/////////(((/((    //
//    (((((((/******/**,***/**,../*****,#%%%#%(/#(%%%#%%##(%%%%%%%/*******/%%%%#****///***////*/*/******//    //
//    ####(((//*******,*******%%&#*,,*#%%%%%&%(&.//*/#%(,##&%%%%%%%%%%##%%%%&%&**,**,*,**************/////    //
//    *********//*********,**(%%&%/%%%%%&&&&&&%.(#*//#,,..%*%%%&&&&&&&&%%&&&&&(****/((//****************//    //
//    //(//////////////////*//#%&&&&%%&&&#/*&&*&&%%(%*,#(,&&#%*/////(%&&&&&%/(///////(((((((((((///////((/    //
//    ((#((((/////////////////*%&&&&&%////((/&&&&/#%%**((*&%%*/*///////(/////////((((((((((((((//////(((((    //
//    ////////////////(////////(((((/////((((%&%%,#%%**##%&&((((((//(///((/////////////////(((((((((((((((    //
//    ((////(((((((((((////////(((/(///////((%%*#%%%%%/%&&&%//(((((////(((/////(//////////////(###(//////(    //
//    ((/////////////((((((/////////////(//(%%%%%%%%&&&&&&&&%/*//////////////////////(////(((((/////(((///    //
//    /////////////(//*/////*/////********/&&&&&&&&&&&&&&&&&&&,**/////*******/***/////////////((////////**    //
//    **///////*/***//**********///*******%%&&&&&&&&&&&&&&&&&&(///******************//*(/**************//(    //
//    ///////***********************//***#%&&&&&&&&&&&&&&&&&&&(*///////**/(((/********/*/***///***////////    //
//    (///(//////************************%%&&&&&&&&&&&&&&&&&&%%*/***/(//****************/*****//*//////(((    //
//    ******/*////////////**///**********%%&&&&&&&&&&&&&&&&%%%%**/*/********************//****************    //
//    ****////*****/************////****/%%&&&&&&&&&&&&&&&&%&&&(/////**//*******/////*************//***//*    //
//    ////**/****/////************(///*/#%&&&&&&&&&&&&&&&&&&&&%%**/*************/////////////(/(/*///(//((    //
//    *#///(///*//*//***//***///(/((((/(%%%&&&&&&&&&&&&&&&&&%%%%#****////****/,//////*****///(/((////(((((    //
//    //####((/*******//*//***///((((((((##&%&&&&&&&%&&&&&&&#/////////////*////(///*****//*//*/*((##(##(//    //
//    ///((((/*///(/((/////((/*////((/(//(/%%&&%%&&(#&&%%%&%///(#((((///((/////(((//(//////////(//((((/(#(    //
//    //((#//////(/#/((#(/////***/////////*%&&&%%&&*&&&&&&&*/*//(#((/(#((//((////(######((((////*////((((#    //
//    ///#///(///#(////////////*/*(//////*/%&&&&&&&#&&&%&&/**///(*//(///***//(/(/(*////****,*//****//(####    //
//    ##(((//((#((//((((/(///(/////////////#%&&&&&&%&&&&&#(((((///(((/////*////(((/(((/(/******////*/(////    //
//    ###(((#(/#(((/((////////(////////////(%%&&&&&&&&&&&((#(###((((((///(/*///(/((((((/*(((((/#/(//(/////    //
//    /((/(((#(#(/(///////(///(((////((/(/((/(/(&&&&&&&&&(((/(/(((((((((((/(((/(((((/(//(///(//////*//((##    //
//    ///(((*((*((//*,**/((((((#(((((((/(/(////(((&&&&&&(*///(((((//(/(////////(///(/(/(//////((//(//(///(    //
//    //*/////////////(((((//#(((((((/#((((((((((/%&&&&%(/////////*/*///((((((((/(////(((((/((/((((//((//(    //
//    ((((/(((///////(((((/(####(((###((##(((#####%&&&&&#(((/////(/((/((((/(((//(////(/#(((#(((/(*((/((/(/    //
//    ###((/#/###///////(((((/*((((#(##(((((((###(,,&#%%%%##(((/#(/////(((/(/(((/#((//(/*((/(//(/*////(((/    //
//    ##(###((####(#((#(#####((###((##((#/(#/(#(####%%%%%#(((#/((/(*(///(/(/(((//(///*,*,*//***/**/////(//    //
//    (//###((#%###%#####((/((((/(///(#/(((/((####(#(*###((((((((/(/(/(/(////((///,*((///((/////**/((/////    //
//    ((((###(##((((#((((((((((/***/(((((,///(%((#((//*####(/(((((/((((((#(/////(,(#(///(/#(/((#//#(//(/(/    //
//    %(####(#(/((#((#((#((#(((##(#####(((///*///#((((/(((/(/(#(#((###(,**(#//(//((/(#*(/*//((((((/(((#((/    //
//    //(####(/(#(#(((//*/###%((%#(%(##(##//////(//((*/(((/(###(#%###/(####(#(((#(((//((((#/##########((((    //
//    ///(/(/##/#(/((((#((/#(/(#(%#(((#(/%/*(/#//*/*//(((((/((*(//##(#(#/**//*(//(/#(/##(((#%#(#%##%##%##(    //
//    /((/*/(//((//(////*//*/////%###(####(((/(/*//(/(/((((((//(//(/////(((/(#//(((*#%#((###*######*##(#/(    //
//    (((((//*/*///*/**(///***//((/((*((#*#(((((((((#(/####(((/(/(#%/((((//%(/#(((/#(/(///####/#%/(((((#((    //
//    #(((/*(///*,/*/(#((((/((#(((#(((##(/%(#((###(##(#%#%%###((%######%%((/*/(#(#/*(*(##(###%#/((/%#(#%(#    //
//    /(##(##/((/(//(##(,((((//#/(((/#,((((((//(##%%//*(((#(%%(#((#%%#(##(####(((#/###%(/#((##(####(#/##(/    //
//    (/(((((((((/(#(##%(#(%(##((((((#//(/(##(,.*/(*#(%((/(#(/#(,%%%#%.,(%#%%%%#%(#*((####(##(#(%#(%##(/(#    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FANG2 is ERC721Creator {
    constructor() ERC721Creator("Cryptofangs Whispers", "FANG2") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bonsai3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    //((((((%%%(///////////////////////*******/////////////*/////////(*(//////////////////////////////////////////////(((((/    //
//    ((/////////////*//////////*//**************////**/****************//***********/****/*///*//******/*/**//////////////(((    //
//    ////////////**************,*,,,,,,,,,,,,,,**,,******,,,,,,,,,,,,,/,,,,********************************/****////////////(    //
//    ************************,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,,,,,,,,*,,,*******************************///////////    //
//    ,,,,,,,,/*****,,,***,,,,.,,,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,,,,,,*,,,,,,,,,,,,*****,,,**************************////*///    //
//    ,,,,.,,,*,,,******,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*.,,,,.,,,,,,,,,,*,,,,,,,,,,,,,,,*,,,**,,,*,************************////    //
//    ,,,,,,,,,,,**,,,*,,,,,,,,,,,,,,,,,,,,,,,,,,,,..*****/,.,.,,,.,,,,*,,,,,,***,******,,,,,,,******************************/    //
//    ,,,,,,,**,,,,,,,,,,,,,,,,,,,,,,,,,,,,,..,.**,./**,,,.,/#..*.,.,,.*,,,,**,,*,*******,,,,,,,,,,,,*,*******,**************/    //
//    ,,*...,,*,,,,,,,,,,,,,,,,,,,,,,,..,,,.(,*,*,,/,***,...,(/(*.,,,,,/,,,*,,,****,,*****,,,,,,,,,,,,,,,,,*,*,***************    //
//    .,,*.,,,,,,,,,,,,,,*,*,,,,,,,,,,,,,*,,,***,**/*,*/%/***/.,,*#%//(,*#(*,,,,/*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**********    //
//    ,,.,.,*,,**,,,,,,,,*,,,,,,,,,,,,,,*/,,//***/**,**/*/(*(((/,(/##(/*((%((%/*#,,,,,,,,,,,,,,,,,,,,,,,,,,,*,,***************    //
//    .,..,.,,,,,,,,,,,,,,,,,,,,,,*,,,,**/*(*,***/,*//(/((##(##/(((*%(#/,*(%((#(/%((#(#/*,/,,,#,/*(/,,,,,,,,,,,,****,*********    //
//    .,,*,,,,,*,,,,,,,,,,,,,,,,,,,,.,,/,*/**/##*%/((/(&##/(#@&%(%&%%&#&((%%(&/#(//#((((@(%%((%*#,#./#,,,,,,,,,,*,***********/    //
//    .,*,,,,,*,,,,,,,,,,,,,,,,*(/#(/#&(*//(%%((&#%#(#(#@&@%(%%((#*&@%%&@#(#/&(%/&&&###&&#@%&%#&%/%/(,,,,,,,,,,,,,**,**,,****/    //
//    .,,,,,,,,,,,,,,,,,,,,,,,(/#%#(/##&&#&(#&@@&&#%/%@@#&%%#%%@@&%@@#&@@@@@@(&#@&@&&&%%@@@@@@/(((%((#%(/&%%#%///,,,,,,*******    //
//    .,*,,,,,,,,,,,,,,,,,*//#/##(#(/&(&@&@@##%@%@#%%(@@@&%@%,/@&@@,,%&#@%@@@@@@@@@@@&@@@@@/@@@@&@@%@%%&%&*##@%@%*/,,*********    //
//    .,**,,,,..,,,,,,,,.%%&#%@@###%#%*&%&@@&@@(@&&%&&&(#&,,,,,@,,,,,,@@@@,,,,,,[email protected]@,,,/...,,.&@@@@@@,,,,,/**,,*,,*,**********    //
//    ..**,,,*,**,*,,*%%@(@@#%#@%&@&%@&&@&%@@&@@&/@@&&&@/,,,,,,@*/[email protected]@@@@@*,,,*,,,,@@.,,,,,,,,,%@&@%,@,,,,,,,,,,,,,,***********    //
//    ..,*,,,,,,,,*,(&&@@@@@@@#&&@@@@@@@@@@@@@@@@@@@@%@@#***,,,@@@@&@@@@@@,,*&@%&%,,,,,,,,,..,,,,,,,#&,#*,,,,**,,,,,*,,**,****    //
//    ..**,,,,,,,,,%@&@@@@%&*@@@..%@@@@@,,*@@@/%@%@@@@@&@*,**,,,@@&@@,,,,@@%/(,./,@@,,/,,,,#&%,&(@&*,*,##%/,,,**,,,,,*,,,,****    //
//    ,,,*,,,,,,,,,/%@@@&&@@(**(,,,&@@@*,@((@@@/%*&/#%@&&%/,,,,*,,,,,,,@@@,,/##%&&&%/&%#@#/(@@%&%(&%#(##&/%#@%&###%#%%#%&%*,**    //
//    ,,,,*,,,,,,,,,,,,,,*/*,**,,,,,,@@&(,***%@@@%(%%(#&#&@@@@.,,*@@@@@@&@@&@@@@@@@@%%%##@&@@##&%(@@@%(&(&#@&%%&&@@@@@&@#@*@**    //
//    ,,,*,,,,,,,,,,,,,,,,/*,,,,,,,,,*@@@@@@@@@@@.,(@%@@@@@@@#@@@@@#&%%*,,,,./@@@@@@@@&@&@@@@@@#&@@%@@@@@@@@@@@@@@@@@**,******    //
//    *,*/**,,*,*,,,*,,,,***,*,/*,,,,*,,,@.,,.,,,.(@@@@#,,,&,%@@@@@@@@@@@@@@@*,,,,,(,,,@@@@,@@@@@@@@@@@@@@@@@@@@@@@.,,*,,*****    //
//    ***/**,,,*,,,,,,,,,*/,**,*,,,,,,*,@,,,,,,,,,#@@*,,[email protected]@@@@@@&&,,%@/,@@@@%*,,./*,,..&&@@@@@@@@@@@@@@@.,,@@@@@@@@@,*,,,*****    //
//    **************,,,,*,**,.*,,,,,,,,@,,,,,,,,,.%,,,,,,,&&@@@@,,,,,,,,@@%&,,,,,,,,,,[email protected]@@&%@,&@&,,@@@@@@[email protected]@@&@@@,*@%*,,,*****    //
//    ***/***********,,,,,.,,,,,,,,,,,.,@,,,,,,,,,@,,,,,@,,,,(@&,,,,,,,,@&*.&@&#@@@@@&@&@@@,,,,,@@@@@@@@((@@@*%@*,,,,*,*,,****    //
//    ***/*,*******//*//*****,*,,,,,,,,,*@,,,,,,,(*,#&(,,,,,@(,****,,@@@@@@@@@@@%@@@@@@(,,,,,,,,%@@@,.,,,,,,@@,,**,***,,,,,,,*    //
//    ,********,,********,*****,,,,,,,,,,@,*,,*,,@@(,,,,,,,,,,#@@@#@@@@@#@@@@,,(,@@@@.,&@,,,,,,,,#,*,,,,,,,,@@,,,,****,,,,,,,,    //
//    ****/****/////*/*/,,,**,,,,,,,*,,,.#**,,,#*,,,,,,,,@@@@(&@@@@%#&@&@,,,,,,,,,,,,[email protected]#,,,,,,.,,*,*,,,**,,,,@@,*,****,,******    //
//    *****/***************,**,,,,,,,,,,@,,**,,,/,,,,,,,@@@/((((#@(/(@@@@@,,,,@@@@@,,,,,,,,,,,,,,,,,,*,,,,,,,,,&*,,,*,********    //
//    /********,*******//**,,,,,,*,,,,,,@(,,,,*,,,,,,,,@@@@@@@@@&@@@@@@@%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,*,,,,,,&/,,,,,**,***/*    //
//    *****/(**,*,,*******,,,,,**,,,,,,,,,,**,****,*,,(@@@@@#&@@@@&&@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,,,*,,@@,,,,,,*,,,**,    //
//    */****#**,*,,,,,(,,,,**,,***,,*,*,,,,***/**,,,,@@@@%@@&&@#@@#&@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@,,*,,,*,*****    //
//    ******(***/**%(*(%&*/*,,,,,*,*,,,,,,*******%@@@@@@@&@&@%(@@&&@@&,,,,,,,,,,,,,,,,,,,,,,,,*,,,,,,,,,,,,,,,,.,,,,,,,,,*,*,,    //
//    ******/***//*/,*(**(***,,,,,,,,,,,,******@@@@@@@@@@@@@%*%#%@/@@@&,,,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(,,*,**,***,,**    //
//    ****/*/***@***/********,,**,,,***@@@@@@@@@@@@@@&#&&&&@@@@%%&%@@&@&&,,,,,,,,,,,,,,,,,,,*,,,,,,,,**,,,,,&,,*,,***,*****,,*    //
//    **/*/*//******************@@@@@@@@@@@@@&@@@*(@@@%%@@@%@#@@@@/@@@@@%@@@&@@@@@@@#.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,******,**    //
//    ******/***********/****%@@@@@&@@@@@%(#(%#//#&%&@@@&@(#%@@%(#((&(@%&@@@@@@(@@@@@@@@@,,,,,,,,,,,,,,,,,**,,,,,*,,,,*****,**    //
//    **//*///**///*****/***(@@@@@@@&@@@@@@@@@@%#@@@@@@@@@@@(@%#@@@@@@@#&&(@@@&%@%@@@@@@@@@@,,,,****,,,*,,,*,*,,,,*****,,,****    //
//    /**//////////////*//*%%@&%(//////%@#%&@@@@&@@@@@@@@@@@/@@@@@@@%%%&@@%&@&#((/////***((%*,,,,****,*,*,*,*,,*,*****,,******    //
//    ////(////////////*//*//#@@@@@@@@@@@@@@@@@@@@@@@&@@@@&%&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,**,,*****,**,***,,,*,*******    //
//    ////(//(/(//////////////&@@@@@@@@@@@@@@@@@@@*,*&/&@*@%@@@(@#@@@@@@@@@@@@@@@@@@@@@@@@@,********************,****,********    //
//    ///////////////*****/////%@@@@@@@@@@@@@@@@@@@*/%**@,@(@@@@@@@@@#@#&@@%@@@@@@@@@@@@@@****,**************,,*,*************    //
//    /////////////(/////***/////@@@@@&@@&&&@@&&@@*/##*/%****(@@@@*//***@@(@&@@@@&@@@&@@&***,*,,,***,*************************    //
//    ///////**///////***/***///(%@@@@@@@&&@@@@#%@&&##(@@@@(@@@@@***@***/@@@&@@@@@@@&@@#(*****************************,*******    //
//    /////////////////*////##%%%&@@@@@@@@@@@@@@%@@%@%@@@@((#((/@@@*//@@@@@@@@@@@&@&@@&%%####(((((((((((((///***********//////    //
//    ((/////////(((((///(####&@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@&%%%#####(##((((((#(((((/**///*//***////    //
//    ((((/(/(((/((//((/#((##%%&%&&&&&@@@@@@@@@@@@@@@@@@&%#(####%%%##((%&&%%%%%%%%%%%%%###%################(((////*//*/**/////    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BSAI is ERC721Creator {
    constructor() ERC721Creator("Bonsai3", "BSAI") {}
}
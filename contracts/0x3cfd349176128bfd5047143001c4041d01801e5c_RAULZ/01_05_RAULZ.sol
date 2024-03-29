// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RAULZ MUSIC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    Hello World                                                                         //
//    ...,,,,,,,,,,,,,,,,,....                 .......                                    //
//    ..,,,,,,,,,,,,,,,,,,.....                .............                              //
//    ...,,,,,,,,,.,,,,,,,....                 ... ...........                            //
//    ...,,,,......,,,.,,....     ,***,,,,.,.    ..,(*..                                  //
//    ...,,,................         .,,,,*//*/*,*,*%%(,*..       ....                    //
//    ......................      .,/**(#%%#%&&&%%#%@@@%(#***.                            //
//    .....,...............   .*/*#(##&&&&&&&@&%%&&%@@@@&@&&#/.                           //
//    ..................... ,/#%&&&&&@@@&&@&&@&&&&&&@&&&%%&&&&#*.                         //
//    ................,/(*/((%%%(/(@@@@@@@@@@@&&&&&&&&@@@@@@&&@&#*                        //
//    ..,,,,,.....,,.*/////(##%%&%/**,,,,********///((###%&&@&#(#/*,.                     //
//    .,,,,,.....,,,..,/%(###%(*,,,,,,,,,,,,*******/////*/*//%@@@@&#/.                    //
//    .,,,,,.........,%((/##(/,..,............,,,,,,,,,*******/#@@@&#*,.                  //
//    ..,,,.........,#/%#%((**..,/#%%%####(/*,,,,,,*,*****,,,,,**&&@@%(,                  //
//    ..,,.........,%@&&#//(&&#,,#%((%%@@@&%*(*(&//%&&&@&&&@&&&&&(%&&@&/.                 //
//    ..,,.........,#&&%*/%*(%&%%%#/%@@@&&&&(,.,%&/&@@@&%&&@@@@@&@&(/&@#/                 //
//    .............,&%#,*(/%%&&&(**(#@@@@@@&,.,,*#@(@@@@@@@@@@@@@%&&*.*%%.                //
//    ..............%%.*.,%%&&@@@@@@@@@@&@#...,,*((&&@@@@@@@@@@@@%&&*,,(#.                //
//    ..........   .((,/..,%&&@@@@@@@&&&#**/*/((((#(%&&@@@@@@@@@@&@#***,/.                //
//    ..........   .(/(/ ..,*/(#((((/**,,(%&&(#&@@&#/**/#&%@@@@@@%(,*,,*/.                //
//    ...........  .(((*. ..,,,,*,,.,,,,,/.,,,**(#%%(/****/(#(/***/,*((*/.                //
//    ,,,,........../##/. .........,,,.....,,*,,,*((/********///**,,*%%,,                 //
//    ,,,,,,,.......,%%,........,,,,...,,..,.*,.,**/#(/*******////*,.,%(.                 //
//    ,,,,,,...... .*,/,,.......,,...,..(((#########//(#(/*///////*,.**(..                //
//    ,,,.......,((#,,.,..,,,.....,**/##/,,,****///%%%%(/(((//////*,.,##(%#,.             //
//    ,,.......,**/,.***,,**,,,..,**....,*/(####((/****/(/((((((//*,.,#%%%&%/*            //
//    ,,........,,*..*,,,,***,,,,,,,,**//*,,.,,*(###(((///((((((((*,,,**((#%(*            //
//    ,,..........*,*/(,.,,***,,*,**,,....,,,,,,,**//(((#(##((((((*,,*%%%#(#/.            //
//    .,...........,**,,.,,**,,,*,,,,,,****///////(((/((########((*,/,*##(%/.             //
//    .,...........,..((.,***,,,,,*,,*//((((############((#######(**%((/*/*.              //
//    ..........     ..,,*//******/((/(##%%%%%%%%%%%%%%%%%%%%%###(,..,**.                 //
//    ..........       .*//(///((((((#%%%%%%%%%%%%%%%%%%%%%%##((/*.                       //
//    ..............    .*((####%%%%%%%%%%%%%%%%%%%%%%%%%%%#((///*                        //
//                                                                                        //
//    raulveiga.com                                                                       //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract RAULZ is ERC721Creator {
    constructor() ERC721Creator("RAULZ MUSIC", "RAULZ") {}
}
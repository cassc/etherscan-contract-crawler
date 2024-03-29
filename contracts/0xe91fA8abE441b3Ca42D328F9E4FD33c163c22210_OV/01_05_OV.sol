// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ORBITAL VENUS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                               .,, ...  .,..                                                                    //
//                                            /,,*,,,,...       .                                                                 //
//                                          ,**,*,,.,.,,,,,,,,,,,,,                                                               //
//                                       .,*/((**(((%%&%%////**,,*(                                                               //
//                                      /##**(%(%#/%&%%&%(/****,,,*,                                                              //
//                                      (*#(&&%%&@#%#%#(/**(///**(#                                                               //
//                                       &(*/%%#((#&%##%&@&#%@&(,((                                                               //
//                                        /#&&@%@&&%##(///////((*,*                                                               //
//                                          %#&&&@&%###(((//((#(%#(                                                               //
//                                             &&&%%%%%%###((((##//                                                               //
//                                               #%%%%%%%%%#((%&&/                                                                //
//                                               ###%%%%%%%%(((((,                                                                //
//                                                ##%%%&@@@@@@@(                                                                  //
//                                                ##%%&&&&%%##(/,,.                                                               //
//                                              /(###%%%%%%%%#(/*,,,..............                                                //
//                                           .((((###%%%%%####(/*,,,......,..........                                             //
//                                        ,*////(((((##%%%#(((/**,,,........,,,,,,,..,                                            //
//                                     ,,,,*****///////////////**,,,,...........,,***/                                            //
//                                  ,,,,,,,,,,,**************,,*,,,,,,..........,,,/((                                            //
//                                 ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,......,,,,,*#.                                            //
//                                /*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,......,,**/                                              //
//                                /**,,,,,,,,****,,,,,,,,,,,,,,,,,,,,,,,..........,/                                              //
//                                (/**,,,,,,,,*#//***,,,,.....,,,,,,,,,,,,.........,                                              //
//                                 /***,,,,.....,&%/*,,,.........,,,,,,,,,,,,*,,***/                                              //
//                                 (//**,,,......,*/*,,....,,,,,,,,,**////////////((                                              //
//                                  (/**,,,,......,/((/((/**********///(((##(##(((((                                              //
//                                   (/**,,,,......,#&&&%###(((((((/////(#%%%%%%###/                                              //
//                                    (/***,,/%&&&&&&@@@@@&&%%%%##(////**//(####((//                                              //
//                                     (/&&&&&&&&&&@@@@@@@@@&%#(/**,,**,,,****//////                                              //
//                                      &%%&&&&%#%%&&@@@@&&%#(////****///*********//                                              //
//                                             .##%%%&%%%%##(((///////////*********/                                              //
//                                              ########((((((/////////////////////*                                              //
//                                             /(######((#%((((((((((((((((((((////                                               //
//                                            ((((((((((/(/(/***************//////*                                               //
//                                           (((////********,,,,,,,,,,,,,,,,,,,,,,,*                                              //
//                                          (///******,,,,,,.,,,,*******,,,,*,,,,,,,                                              //
//                                         ///****,,,,,,,,,,.....,(#,,......,,,,,,,,*                                             //
//                                        ///*****,,,,,,,,,,,.,,...........,,,..,,,,*                                             //
//                                       *************,,,,,,,,,,,,,,,,,,,,,,,,,****,*                                             //
//                                      /**,,,,,,,**********,,,,,,,,,,,,,,,,**,,,,,,,,                                            //
//                                      /**,,,,,,,,,,***************,*,,,,*****,,,,,,,                                            //
//                                     /*****,,,,,,,,,************,**********,,,,,,.....                                          //
//                                     *****,,,,,,,,,,,,,,*****,,,,,,,,,,,,,,...  ,,**.,,                                         //
//                                    /*****,,,,,,,,,,,,,,,,,,,,....,,     . ..*..,.*,*,,,                                        //
//                                   *//*****,,,,,,,,,//******...,(/#&&&(..,,..*,.*,..*,.*                                        //
//                                  *..,(/****,,,,.(/,,....,,..,,....,,..*,.*,..,,....(*(..                                       //
//                                ,.,,...,......%,...,%#(&&&#,.(#%(/*...*.#,..,...//,*...*/(                                      //
//                                %%&(*..*#@/,**,(/(***/&&&#((**%#,/,,*,/,*#%##%&&@,..*#%                                         //
//                                ((##(#/(%%&%%%%(##(***//*////(&&&&&%%##%%/...,...,*,*/*/                                        //
//                                (////(((((((((/***///***#%&&#/(/#//*.,,.,.,,......,,...*,                                       //
//                                *,************/*//#%&%%&%(/%/#//**,,,,,,.,..............,                                       //
//                                 %%&#(((((((#/@%%%&%%#(*(/%/#/(//,*.,,,,*......,........,,                                      //
//                                    #%&#%%%%%&##%/(*/((/(%/#/#//******,*,,.............,/*,                                     //
//                                    #%%##(&(##//(#*(%/,%%/#/#(******/,*,,,,.............,**                                     //
//                                    @#((/%##((*//(#/(#%#(#(#//***((*,**,,,................,                                     //
//                                     *(####(((#(//(%((#(#/((//**&///***,,,,,.....,,**/****#*                                    //
//                                      ((#%#(((((//((#(/#/((///(%/#/******,,..,*/(,.....,*@@/                                    //
//                                     #&(%%((((((//(((/./&#(((##%(/**///***,,,,,.........,&@%*                                   //
//                                     %(#&#(#((((((((//%&%##/###/#***//****,,,,..........,*@(*                                   //
//                                     /(&&##(((((((/*#%&%##(#&(%(#**/(/**/***,,,,.........*&#/                                   //
//                                      .&&##(((((((/%%%%###(%&(##*//(#(////(**,,,,......../*%/*                                  //
//                                         #(((((((/%%%####/%&&//%***##/(//((//****,,....,,,@//*                                  //
//                                          (((((/&%#%#####(%&%(#,**/##((((((/////*/****,,**(#(/,                                 //
//                                          (((/(%#&%##(#(/#%%%(#**//%%#(((/(((((/(((///////*#&(/,                                //
//                                         ,(//&%%%&%###(//%&%&((/*/(%#%##((#((#((###((((//**#@#(*                                //
//                                       ,**%@&&@#&###%((/%&&%%(#(///%#%%##(%(#########((///**%%(/*                               //
//                                      /%&&@&@&#%#(##(*%%%&%%%#%%(((#(#%%#(%(#(#%%%###((//***#&//**                              //
//                                       #%@@&#%%#(##((%%%&%%%%#&%%%(#((###(#%(#%%#####((//****&%/**                              //
//                                          (#%#((##(/#%#&%%%%##%%%#,,((((#%/(#%%%%#####((/****#%//**                             //
//                                           ##((#((#%%#&%%%%%##%%##((&@@@&%(%&%%%####(#((//****%#//*,                            //
//                                           #((#(((%%(&&%%%%%%#(###(/#%@%%(%&&&%%######(((//***/%(/*,                            //
//                                           ((##(#&%(&&%##%%%%%(#(((#(%%(#&&&&%%%######((/*/***/%#//,*                           //
//                                           (#(/#&#(&&%##%%%%%%/(((((#(/%&&@&%%%#####(((////***/%#(/*,                           //
//                                            #(%&(#&&%##%%%%%%%%%/(((%#&&&@&%%%#######(((((/**//&%///*                           //
//                                            (@%&%%%%###%%%#%%#####%(&&&@@&%%%%#####(/(#((/(//**#%#***(                          //
//                                           /#%@%#&&###%%##%%######&&&@@&&%%%%####(/(#(((#((//**/&#((,                           //
//                                          %@@&%#&&%##%%#%%##(((#(%%@@@&%%%#####(/#&(((%%(((//***#@((                            //
//                                              (#&%##%%#%%#(((%/&#@@@@&%%####((/&&/#%&%%##((//****(//                            //
//                                               #%##%%#%#(//(*%%@@@@&%%###(((#&((&&&&%%###(((//*****/                            //
//                                                ##%##(/(%*#@@@@@&&%%###(((@/%&&@&&&%%%####((//**/**/*                           //
//                                                 #(/(@#%@@@@@&&%%##((/#%(&&@@@&&&&%%%######(//**(*/*/                           //
//                                                *@&%#@@@@@&%%##((/((*#&@@@@&&&&%%%%#######(((***%**#,                           //
//                                                 ,%%%%####(((*/%@@@@@@@&&&&%%%%%%%#######((((/**//*%*,                          //
//                                                  /((/(&@&&&&@@@@&&&&&&&&%%%%%%%#######(((//**,,,/*,(,*                         //
//                                                   ((((##%%%%%%%%%%%%%###############(((((//**/(##,***                          //
//                                                   /##*,,*/((###############(#(((((((((((((/*#((((#.,,,                         //
//                                                 &##/,,,*,*/////(((((((((#((((((((((/((((/*((**/****(..,                        //
//                                ,,,,,,,,,,,*****%**/#%*.,,,,,**************///////*****////*,,***,,,./,                         //
//                                (,..,,,,,,,,,,,,*..,....,(,*,,,*,,,******/**///((###((///(((((/*,,,...                          //
//                                ((/.........,,,*#*,,.,.*,..,.,,,,,,,,,,,,,,,,,,,,,,,***/(@@**,,,,,...                           //
//                                ((((,..........,,.*,,..**,,/,(,,,,,,.,,,,,..,,,,,,,.,,%(//(........,                            //
//                                  ((((.............................,,,,,..,,,....................,                              //
//                                   ((((,........................,,,,,,,.,,,,,,**************,..,                                //
//                                    (#((*****/***//*****/*******/*,*#######%/*/*****/****//*#(                                  //
//                                       (/*/*/***,*****(###%%##%%&%%######%#(#(*/(////*/((##                                     //
//                                        #####(///*/(##*,.                                                                       //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OV is ERC721Creator {
    constructor() ERC721Creator("ORBITAL VENUS", "OV") {}
}
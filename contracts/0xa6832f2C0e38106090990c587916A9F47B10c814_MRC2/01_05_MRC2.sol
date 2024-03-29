// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MrC Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//        __  ___     ______   ______    ___ __  _                                        //
//       /  |/  /____/ ____/  / ____/___/ (_) /_(_)___  ____  _____                       //
//      / /|_/ / ___/ /      / __/ / __  / / __/ / __ \/ __ \/ ___/                       //
//     / /  / / /  / /___   / /___/ /_/ / / /_/ / /_/ / / / (__  )                        //
//    /_/  /_/_/   \____/  /_____/\__,_/_/\__/_/\____/_/ /_/____/                         //
//                                                                                        //
//    &&&&&&&&@&&&&&&&&&&&&&&&&&&&&&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@&&&&    //
//    &&@&@@&&@&&&&&&%&&&&&&&&&&&&&&&&&&&&&&&#/,,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@&&@@@    //
//    &&&&&@@&&&&&&%&&&&&&&&&&&&&&&&&&&%(...,,,,,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&%%&&&&&&&&&%%&&&&&&&&&&&&&&&&%,....,,,,,(&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&%&&&%%%%&&&&%&&&&&&&&&&&&&&*........,,,(&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    %%&&%%%%&&&&&&%&&&&&&&&&&&&&&*,...........*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    %%&%%%&%%&&&&%&&%%%%&&&&&&&%*,............,%&&&&&&&&&&&&&&&&&&&&%##%%%%#%#%%(/%%    //
//    **(%%%%%%%%%%#%%%%%%%%#%%%%(,...,..........,%%%%%%%#%%%%##%%####%#((((((////(**/    //
//    /////***,,*/((#(((#########.......    .    .*/*///#(////**//////**/(%%&%&%&&&%&%    //
//    &&&&&%%%%%%%%(##(%%##(##((.... .............,,(#(((#%%%%%%%%%%&&&%&&&&&&&&&&&&&&    //
//    %%%%&&%%%%%%%%%%%%%%%%,(%/,,,,.............,,/%/,.(%&%%%%&&%&&&&&&&&&&&&&&&&&&&&    //
//    %%%%%%%%%%%%%%%%%%%%.,......,,,,*,,,,*,,,,,......,#*.,%&&&&&&&&%&&&%%&&&&&&&&&&&    //
//    %%%%%##%%%%#%##///,,,.,,*,.,**///*/////***,,*,,,....,#/%%&&&&&&%&%&&&&&&&&&&&&&&    //
//    %%%%%%##(((///***//,,,*/(//(/((((((((((#*,*##%#(,*,,..*(%%%&&&&%&&%&&&&%&&&&&&&&    //
//    ##((((///(#&@#(/(/////*/////(//(///**/(#*,*((#####%/*,,*,%%%%%%%%%&%%%%%&&&&&%&&    //
//    %%%%%%##//////(//((/(#*.*/*/(/(////*/****,*%#####(#%#(,,.*%/%&&%%&&&&&&&%%&&&&&&    //
//    %%%%%#%(/////////((//(#,.*/(//(////#%(**,,*(###(#%##(((,,//(##%%%%%%%##((((#####    //
//    %%%%%%%%(///////(//(((#/..///////(/(#%%(,,*(#(#(#%%(#%,*////(((##########%%%%%%%    //
//    %%%%%%%%%%#(///////(////*../////(((/((#*.,*#%%#(((((*,//(((#######%%%%%%%%%%&&&&    //
//    %%%%%%%&%&&&%#(((////////,../(///(((((/..//((///(//,/((#####%%%%%%%%%&%&&&&&&&&&    //
//    %%%%&%%%&%&%&%%%#(((/(((((...///((///*..*/((////(,*((###%%%%%%%%%%%&&&&&&&&&%%%%    //
//    &%%%&%%&%&%&&%%&%&&&&%(((//.  ,////// .,..,#*,.*/((####%%%%%&%%%%%%&&%%&&&%&%&%&    //
//    %&&%%%%%%%%&&%%%&&&&&&&&&&&%(. ...,*,.,,,,/(%&(%&###%%%%%%%%&%&%%%%%%%&&&&&&&%&&    //
//    %&&&&&&&&&&%&&&&&&&&&&&&&&&&&&&%%##%%#%%%%%%%&&&&%%%%%%&&&&&&&&&&&&%%%&&&&&&&&&&    //
//    &%&%%&&%&&&&&&&&&%&&&%&&&&&&&%&&&%%%%%&&&%%%&&&&&%%%%%%%&&&&&&&&&&&&&&&%%&&&&&&&    //
//    &&&&&&&&&&&&&%&&&&&&&&&&&&&&&&&&&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&%&%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%&%&&&&&&&&&&&&&&&%    //
//    %%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    %%%%&%%&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&%&&&&&&&&&&&&&&&&&&&%&&&&&&&&&&%&&%%%%&%%&&    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MRC2 is ERC1155Creator {
    constructor() ERC1155Creator("MrC Editions", "MRC2") {}
}
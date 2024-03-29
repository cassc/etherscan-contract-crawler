// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stonez The Organic Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//     ______   ______    _______    ________   ___   __     ________  ______                                                                                  //
//    /_____/\ /_____/\  /______/\  /_______/\ /__/\ /__/\  /_______/\/_____/\                                                                                 //
//    \:::_ \ \\:::_ \ \ \::::__\/__\::: _  \ \\::\_\\  \ \ \__.::._\/\:::__\/                                                                                 //
//     \:\ \ \ \\:(_) ) )_\:\ /____/\\::(_)  \ \\:. `-\  \ \   \::\ \  \:\ \  __                                                                               //
//      \:\ \ \ \\: __ `\ \\:\\_  _\/ \:: __  \ \\:. _    \ \  _\::\ \__\:\ \/_/\                                                                              //
//       \:\_\ \ \\ \ `\ \ \\:\_\ \ \  \:.\ \  \ \\. \`-\  \ \/__\::\__/\\:\_\ \ \                                                                             //
//     ___\_____\/_\_\/ \_\/_\_____\/___\__\/\__\/_\__\/ \__\/\________\/_\_____\/__                                                                           //
//    /_____/\ /_____/\  /_______/\/________/\/_______/\/_____/\ /__/\ /__/\ /_____/\                                                                          //
//    \::::_\/_\:::_ \ \ \__.::._\/\__.::.__\/\__.::._\/\:::_ \ \\::\_\\  \ \\::::_\/_                                                                         //
//     \:\/___/\\:\ \ \ \   \::\ \    \::\ \     \::\ \  \:\ \ \ \\:. `-\  \ \\:\/___/\                                                                        //
//      \::___\/_\:\ \ \ \  _\::\ \__  \::\ \    _\::\ \__\:\ \ \ \\:. _    \ \\_::._\:\                                                                       //
//       \:\____/\\:\/.:| |/__\::\__/\  \::\ \  /__\::\__/\\:\_\ \ \\. \`-\  \ \ /____\:\                                                                      //
//        \_____\/ \____/_/\________\/   \__\/  \________\/ \_____\/ \__\/ \__\/ \_____\/                                                                      //
//                                                                                                                                                             //
//                   .                                                                                                                                         //
//                 .-==.                 --:.                                                                                                                  //
//                .:--+*-               :==--                                                                                                                  //
//                      ::*+:           :-=:. .               . .  .                                                                                           //
//                       .-%#+-:.       :--=...         .....:::--::                                                                                           //
//                         .+#*=:        .+++-.    ..... .=-.                                                                                                  //
//                           .-*#*=-:...:=+++-: .:-:  :::.                                                                                                     //
//                              :=*%%*+- --===. ..:  ::                                                                                                        //
//                                 -#**+=.   .:.    .                                                                                                          //
//                                  +*+++=-.  .:.                                                                                                              //
//                                  .+++++=-.  =:  .                                                                                                           //
//                                   =+++*++=:.==--.                                                                                                           //
//                                    +++***+=-=:::                                                                                                            //
//                                    :++***+=++=-:                                                                                                            //
//                                     =+***+=+=-=:                                                                                                            //
//                                     :=++++=+=:..                                                                                                            //
//                                    .-=+++=-=-..:                                                                                                            //
//                                   .-=+****++===-                                                                                                            //
//                                   -+*****++==-:.                                                                                                            //
//                                   +*****++==-. .                                                                                                            //
//                                   +****%#+==:  .                                                                                                            //
//                                   ****#%+==-:  .                                                                                                            //
//                                   +#####---:: .                                                                                                             //
//                                   .###*+--::...                                                                                                             //
//                                    =%%#+:-: .:                                                                                                              //
//                                     +#%*:-- :                                                                                                               //
//                                      ::-:--:.                                                                                                               //
//                                        +---.                                                                                                                //
//                                        -:-:.                                                                                                                //
//                                        ---..                                                                                                                //
//                                       :---::                                                                                                                //
//                                       .----                                                                                                                 //
//                                       :---.                                                                                                                 //
//                                       :-..                                                                                                                  //
//                                       -..                                                                                                                   //
//                                      ::                                                                                                                     //
//      ...................             -: .                                                                                                                   //
//    ..................................-:..                                                                                                                   //
//    ..............::::::::----==+++*****+-.....                                                                                                              //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ORGED is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
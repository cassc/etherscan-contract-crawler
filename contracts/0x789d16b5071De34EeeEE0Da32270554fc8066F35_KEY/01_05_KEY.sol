// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CTRL-ALT-BONE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ####################################################&*%####&##&%%%...%####%...%#    //
//    ##########################################%..,**...%%#%%%%%&##%%###%%%%%%%###...    //
//    #################################&#%#%%%###********%...%%#%#&%%%%#&&###%##%%%%##    //
//    #######################%.#..%%#%##%%%%%%%%%%###%*(..(***(##%%###%%%%%%%&%#####%%    //
//    #################.*#...,******%%%%%###&%%%##%%%%%##%%###%%&%%%%#&%###%%&%&%%%%%#    //
//    #####.%####%%%%#&%%*****....***....%%%%%&%&%####%%%%%%%%%%###&%%%%%%%%#&%%#%#%.%    //
//    ###*..%%%%%%%%%#%%%####%**%******%####%%&##%%&%%%####%%##%%%%%&#####%%%###%#&...    //
//    %%%***.#%#########%%&#%%%##%%&####%%%%%%%##%%&###&%%%%%%########&####&(...#....*    //
//    %%%%%**..%%%%%%%%####&%%&##%%%&%#%&####%%&#%%%&%%###############*...(.....######    //
//    %%%%%%***.*%%###%%##%%%%%%%%%%####%%%%%%&%%########%######....*.....############    //
//    ##%%%%%%**..%%%%%%%##########%%#%%%&###%%%###%######....,.....##################    //
//    ###%%%%%%&**..%%##&###%%%%%%&###%%%#&#&##%%##%..........%#######################    //
//    ######%%%%%***.%%%%%%&##%#%%#&####%%###&..........&#############################    //
//    #######%%%%%%**..%%####%##%%%####&..........(###################################    //
//    #########%%%%%%*(.%%%#######.....,....,#########################################    //
//    ###########%%%%%**..#/.....*.....###############################################    //
//    #############%%%%%*%./.....#####################################################    //
//    #################%%(.%##########################################################    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract KEY is ERC1155Creator {
    constructor() ERC1155Creator("CTRL-ALT-BONE", "KEY") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frontier Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&&&&&&&&&&&##########################################################################&&&&&&&&&&&&&    //
//    &&&&&&&&&&###############################################################################&&&&&&&&&&&    //
//    &&&&&&&&####################################################################################&&&&&&&&    //
//    &&&&&&###################################BBBBBBBBBBBBBBBBBB###################################&&&&&&    //
//    &&&&##############################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##############################&&&&    //
//    &&###########################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB############################&&    //
//    ##########################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#########################&    //
//    #######################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#######################    //
//    ####################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB####################    //
//    ##################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##################    //
//    ################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB################    //
//    ###############BBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBB###############    //
//    #############BBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBGGGBBBBBBBBBB#############    //
//    ############BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGPPPPP55555555555555PPPYPBBBBBBBBB############    //
//    ###########BBBBBBBBBBBBBBBBBBBGGGGGPPPP555YYYYYYYYYYY555PPPGGBBB##&&&&&@@@@@@#?BBBBBBBBBB###########    //
//    ##########BBBBBBBBBPP5555YYYYYYYY555PPPGGBBB###&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@JG#BBBBBBBBB##########    //
//    #########BBBBBBBBG?5GBB###&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@55#BBBBBBBBBB#########    //
//    ########BBBBBBBB#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GJ##BBBBBBBBBB########    //
//    #######BBBBBBBB##B7&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG#@@@@@@@@#?##BBBBBBBBBB########    //
//    #######BBBBBB#####[email protected]@@@@@@@@@@@@@@@@@@@@@@@@&&##BBBGGB#@@@@@@@@@@#!^[email protected]#&@@@@@&?B#BBBBBBBBBBB#######    //
//    #######BBBBBB#####[email protected]@@@@@@@&GPP&@@@@@@@@@#Y7!~~^^^^^^^~?#@@@@@@57Y##@Y^!#@@@@@YP##BBBBBBBBBB#######    //
//    ######BBBBBBB#####[email protected]@@@@@@@&!^^G#B&@@@@@&7^^^75PPGBB?^^^[email protected]@@@@@57Y#P5BGB&@@@@@PY##BBBBBBBBBB#######    //
//    ######BBBBBBB#####B7&@@@@@57!~^^~^^[email protected]@@@@&7!77#@&BG5Y!^^^[email protected]@@@@@@@@[email protected]@@@@@@@BJ##BBBBBBBBBBB######    //
//    ######BBBBBBB######7#@@@@@P7J?^^[email protected]@@@@@&&@@@Y^^^^~7?YP&@@@@@@@@@@&&@@@@@@@@@&?B#BBBBBBBBBBB######    //
//    ######BBBBBBB#####&[email protected]@@@@@@@#[email protected]@@@@@@@@@@@@@5JYYG&@@@@@@@@@@@@@@@@@@@@@@@@@@@JG##BBBBBBBBBB######    //
//    ######BBBBBBBB#####[email protected]@@@@@@@@&&&@@@@@@@@@@@@@@GJ???#@@@@@@@&GPG#@@@@@@@@@@@@@@@55##BBBBBBBBBB######    //
//    ######BBBBBBBB#####[email protected]@@@@@@@@@@@@@@@&BB#@@@@@@P^^^^[email protected]@@@@@P~^^^^?&@@@@@@@@@@@@@GJ##BBBBBBBBB#######    //
//    #######BBBBBBB######7&@@@@@@@@@@@@@&Y~^^[email protected]@@@&PPGG#@@@@@@J^^^^^^#@@@@@@@@@@@@@#?###BBBBBBBB#######    //
//    #######BBBBBBB######[email protected]@@@@@@@@@@@@B^^^^^^[email protected]@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@&?B###BBBBBB########    //
//    ########BBBBBB#####&[email protected]@@@@@@@@@@@@@5!~~!J#@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@YP####BBBBB########    //
//    #########BBBBB######[email protected]@@@@@@@@@@@@@@&##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&###BBBPJB#######B#########    //
//    #########BBBB#######B7&@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&###BBBGGGPPPP5555555PPPPPGGG###################    //
//    #####################[email protected]@@@@@&&&&###BBGGGPP55555YYY55555PPPPGGBBBB######&&&&&&&&####################    //
//    ####################&GJ5555555555555PPPPGGGBBBB#####################################################    //
//    #####################&#BB######&&&&&&&##############################################################    //
//    ########################&###########################################################################    //
//    ##########################################################BBBBBBBB##################################    //
//    ###########################################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#######################    //
//    ###################################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#####################    //
//    ##############################BBBBBBBBBBBBBBB555P55PY5YBBBBBBBBBBBBBBBBBBBBBBB######################    //
//    #############################BBBBBBBBBBBBBBBBPGGGPGGPPPBBBBBBBBBBBBBBBBBBBB#########################    //
//    &&###########################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##########################&&    //
//    &&&#############################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##############################&&&    //
//    &&&&&#################################BBBBBBBBBBBBBBBBBBBBBBB##################################&&&&&    //
//    &&&&&&&######################################################################################&&&&&&&    //
//    &&&&&&&&&&################################################################################&&&&&&&&&&    //
//    &&&&&&&&&&&&############################################################################&&&&&&&&&&&&    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FTR is ERC721Creator {
    constructor() ERC721Creator("Frontier Pass", "FTR") {}
}
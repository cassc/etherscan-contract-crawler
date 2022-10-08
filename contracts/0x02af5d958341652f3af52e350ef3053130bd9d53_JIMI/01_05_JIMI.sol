// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jimi Albert
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//         | _)            _)       \     |  |                  |                                   //
//         |  |  __ `__ \   |      _ \    |  __ \    _ \   __|  __|                                 //
//     \   |  |  |   |   |  |     ___ \   |  |   |   __/  |     |                                   //
//    \___/  _| _|  _|  _| _|   _/    _\ _| _.__/  \___| _|    \__|                                 //
//                                                                                                  //
//                                                                                                  //
//    ################################################################################S#SS######    //
//    #########################################SSSSSSSSSSSSS####################################    //
//    ####################################SSSSSS%%%%%%%%%%SSSSS#################################    //
//    ##################################%%%SSS%%%%%%%%??%%%%%SSSSS##############################    //
//    ################################S%??%%%%%?????????????%%%SSSSS################S%%%%%S#####    //
//    ###############################S??????????????*******???%%SSSSS###############S%%%??S#####    //
//    ###############################??**********************???%%SSS###############S%%%?%S#####    //
//    ##############################S*****?????******++*****????%%%SSS###SSS######SS%%%%%%S#####    //
//    ##############################S*++++**???***************???%%SSS##SSSS#####SSS%%%%SS######    //
//    ##############################S*++*******************+****??%%S##SSSSSS###SS%%%SSSS#######    //
//    ##############################S*+*%%%%???**++++++++*+**??%SSSSS##SSSSSSS######SSSSS##S####    //
//    ############################S%S*+*+**??%%%**+++++**?%SSSSSSSSSSSSSSSSSSS##S#########SSSSSS    //
//    ############################?***+;+**?%%???*+;+**?%?%%%S%%%SS%%S%??SSSS###SSSSSSSSSSSSSSSS    //
//    ############################%*+++++***%%?%%?*+*??%%*???%%%%S%?%S???SSS###SSSSSSSSSS#######    //
//    #############################?+?++*+;++**?**++*??%??***+**???%SS*%SS##SSSSSSSSSSSSSSSSSSSS    //
//    ###########################S#%*%++********++++**?%???********%SS?%SS##%??%%SSS%%%%SSSSSSS#    //
//    ###########################S#%+?*;+******+++++***?%?****++**?%S#%SSSSS%%%%%%%%%??????%%SSS    //
//    ###################SS######S#S*?*;;+++++++++;;+++*??*++++***?%S#%SSS%%%%SSSSS%%%%%%%%%%%SS    //
//    ###################SS#SS###SSSSS?+;;+++++*++*++++???**+++***?%S#%%S%???%%SSSSSSS%%%SSSSS%%    //
//    ################SS#SSS#####SSSSS?++;+++*??%S#S%?%S#S%???***?%S##%????**??%%%%%%%SSSSSSS%%%    //
//    ###############SSSSSSS#S###SSSS#%*+++??%SSSSSSSSSSS##SSSS%?%SSSSS?****+++++++***????%%%S%S    //
//    ###############SSSSSSS#S###SSSS#S*+**?S%???**?????%SSSSSSSSSSSS##SSSSSSSSS%%%%%%%%?**?%%%%    //
//    #############SS#SSSSSS#S###SSSSS#%????%?+;;+*???????**??%SSSS######################%?S####    //
//    #############SS#SSSSSSSSS##SSSSS#SS%??%%?*++*?%S%%?**?%SSSS#######################SS%?%%%S    //
//    #################SSSSS##S##SSSSSSSS**?%%%**********?%SS###SSSS################SSSSSS%?S%%%    //
//    SS################SSSSS#S#SSSSSS#S?+;+*??**???**??%SSSSSSS%SSS%S############%?*??%%SS%S###    //
//    SSS################SSSS###SSS#SS#S??+;++***?SSS%SSSS%S%%%%?%SS%SSS##########SS%%?***??SSS#    //
//    SSS####################SSS%#S#SS##S%?*;;++++***??????????**?%%%SSS################SS%?%??S    //
//    ##################SSSSSSSSSSS#SSS#SSSS%*++++++++++**********?%SSS######################SS#    //
//    #########SSSSS%SSSSSSSSSSSSSSSSSSSSSSSSS?**+++++++++++******?SSS##########################    //
//    #########??%?*?SSSSSSSSSSSSSSSSSSSSSSSSSS?**+++++++++++****?%SSS##########################    //
//    #######S?*+?S%?%SSSSSSSSSSSSSSSSSSSSSSSSSS?*++++++++++****?SSSSS###S###SS#################    //
//    ##SSS%%?%%?*?SS%SSSSSSSSSSSSSSSSSSSSSSSSSSS%*++**********%SSSSSSSSS##SSSS#################    //
//    *+;;+++*?SSS%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?*********?SSSSSSSSSSSSSSSSSSS###############    //
//    ;;;;+*?%?*%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?*****?%SSSSSSSSSSSSSSSSSSSS###############    //
//    ?*+****?%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%?%SSSSSSSSSSSSSSSSSSSSSS#SS############    //
//    +++**?????%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS############    //
//    ;++**??%%S%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#SSSSSSSSSSSSSSSSSS#############    //
//    ++***??%SS#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#SSSSSSSSSSSSS###################    //
//    ****??%%SS####SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##S################    //
//    +++**??%%SSSS#####SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#SS################    //
//    ++***??%%SSSSSSSSSSS###SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS###################    //
//    ***???%%%SS########SS##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#SSSSSSSSSSSSSS####################    //
//    +++**?%SSS##############SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#SSSSSSSSSSSSS#####################    //
//    ++**??%%SS##############SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##SSSSSSSSSSSS######################    //
//    ++*????%%%%%%%%%SSS#####SSSSSSSSSSSSSSSSSSSSSSSSSSSSS##SSSSSSSSSSS########################    //
//    +*******???%??????%%SS###SSSSS#SSSSSSSSSSSSSSSSSSS#SS##SSSSSSSS###########################    //
//    +;;++**??%%%%?????%%%%S########SSSSSSSSSSSSSSSSSS##S#######S##############################    //
//    ;;++**??%%%%??????%%%%%S##########SSSSSSSSS###############################################    //
//    ;;+**???%%%?????%%%%%%%S##################################################################    //
//    ;++*??%%%%%%??%?%%%%%%%S##################################################################    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract JIMI is ERC721Creator {
    constructor() ERC721Creator("Jimi Albert", "JIMI") {}
}
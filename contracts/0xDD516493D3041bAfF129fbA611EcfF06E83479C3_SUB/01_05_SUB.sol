// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unstoppable SubDomainz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ####################################################################################################    //
//    ####################################################################################################    //
//    ####################################################################################################    //
//    ##########################################################################( .#######################    //
//    ######################################################################,     .#############(**/######    //
//    #################################################################(          .##########/*,***/######    //
//    #############################################################.              .#######****,****/######    //
//    #########################################################                   .###(************/######    //
//    #####################################,,,,,,./############                   ./,*,*,*,*,*,*,**/######    //
//    ###################################.*,,,,,,,,,,,,.#######                    ***,************/######    //
//    #################################/*,,,,,,((#((,,,(*######                    ***,*******,****/######    //
//    ################################**,,,,,*/(/***(*,,,######                    ***,************/######    //
//    ################################.**,,,,,,,,,,,,,,,.######                    ***,***,***,****/######    //
//    #############################/  (**,,,,,,,,,,*(#.########                    ***,************/######    //
//    #########################.      /**,,,**///((#(##########                    ***,*******,****/######    //
//    ####################(          (****/((((*############***                    ***,************/######    //
//    ####################(         ,**,,,**/(,##########******                    *,,,,,,,,,,,*/#########    //
//    ####################(        .*,,,,,,**/ ######(,,**,,***                    ***,***/###############    //
//    ####################(        *,,,,,,,**/.###****,*******,                    */#####################    //
//    ####################(       *,,,,,,,,**/.*******,***,........               .#######################    //
//    ####################(      **,,,,,,,,*,(.*****,,**,,,,,,,,,,,,,,,,,         .#######################    //
//    ####################(     **,,,,,,,,,*(#,***,***,,,,,,,,,,,,,,,,,,,,,,.     .#######################    //
//    ####################(    .**,,,,,,,,**((,**#,*,,,,,,,,,,,,,,,,,,,,,,,,,*.   .#######################    //
//    ####################(    .***,,,,,,***/#*,(*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*. .#######################    //
//    ####################(    ****,,,,,***/((#/*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*** .#######################    //
//    #####################    /****,,,***((*/**,,,,,,,,,,,,,,,,,,,,,,,,,,,*****(.,#######################    //
//    #################(***    (*****,,,,,,,,,,,,,,,,,,,,,,,,,,**************//(# (#######################    //
//    ##############/******,  .(*******,,,,,,,,,,,********************,(/(/(/##  .########################    //
//    ###########*,*,**(####* ./*********,,**,,*********,**/((//(///////((*      #########################    //
//    ########*,*(###########/ /(#####(((#####(/////////////((#(((#,            ##########################    //
//    ####/(###################                                               /###########################    //
//    ##########################(                                           ,#############################    //
//    #############################                                       /###############################    //
//    ###############################(                                 *##################################    //
//    ###################################(                         *######################################    //
//    ##########################################/           *#############################################    //
//    ####################################################################################################    //
//    ####################################################################################################    //
//    ####################################################################################################    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SUB is ERC721Creator {
    constructor() ERC721Creator("Unstoppable SubDomainz", "SUB") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Novus Ordo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    (.%%                                                                                //
//                  %% %%% %%%  % %% .%% %%       % %%% % % %%, %% % % %%/                //
//                  %%.%%% % %  % %% %,  #%       % % % %%% %.% %% %%% %.%                //
//                  %  %.% %(% /% %/ %%/ #%   /   % %#% %/% %%% %% % % % %                //
//                                                                                        //
//          ,  /                                                                          //
//        (((((////*****,,,,....                                                          //
//                                                                                        //
//                  @@@@  @ @@    @@&   @@   @ @ @@ & @ @  @@   @@@  @ [email protected]                 //
//                                                                                        //
//                                          @.  ,#                           @  @/        //
//                                                                  @ /(@% ,%(  *         //
//          . *.,...*@@@@@@@@@@@@@@@@@@@@@@@@@*  ,%.# %,#% .*@*,          @@(@%@          //
//                ,  ,  #@%#%@@%#@@@@@@@@@@/#@*  @@@#@#@                                  //
//         .. *..*. , . . ,#%%@#%%%@@@@@%@#/%&*                            . &(@          //
//         .      ... .  . .,@@@@@@@@@&@@@@%@@*  @@@( (&                                  //
//         .,,. ..   ... ..      @@%@@@@@@@@@@*                                           //
//          *,.  .    .   .    *   @@@@@%%%@%%,                                           //
//            ...,  ....  ...  *@@&*@@@%%%%@%%,                                           //
//          , ,. . .*@,,@ * #  . .# @@@%%%%@%@,                                           //
//         ,, * .* @@,, , , .   .  [email protected]@@@@%%@%%*                                           //
//                [email protected]@@@@& ,@@.  /  /%@@@@@@@@@*                                           //
//         . .   [email protected]@,@@ .,,  *@@@ @@@@%@@%@@, *%% %%% %*%*%%% %%   %%%*%%%*%% (%%       //
//             ,  ,   .*   @ . ,(@@@.,@@@@@%@@* %%% %%% %%%%%%%%%%   %%%%%% %%% %%%       //
//         .  ,  .,   [email protected]@# @@#*.., . [email protected]#%@%@@* %%% %%% %%%%%%%%%%   %%%%%%%%%% %%%       //
//             .  ..  . @.%%#(% . . . , @/%%@@* %%% %%% %%%%%%% %%   %%%%%%%%%% %%%       //
//                                              %%% %%% %%%%%%%%%%   %%%%%%%%%% %%%       //
//                                              %%% %%% %%#%%%% %%   %%%%%%%%%% %%%       //
//                                              %%% %%% %% %%% %%%   %%%%%%%%%% %%%       //
//                                                                                        //
//          @/ @  @#. #@#@ [email protected] @@@   @ @@ @, @@@@    @@,@  & @/ @* @&@ @ @ @@ @@@,         //
//                                                                                        //
//         *@@  @ @*@@  @@ @  &   *@   @@ @%%,%% %,%/% % #% %%%%@                         //
//         @@**@@ @@@@@ @@ @  @   @@   @@ @ %%%% % %#, %  % #%.(@                         //
//          @@  @ @*@@  @@ @  &    @   @@ @%% %% %,% % % (% %%%%@    ...,,...             //
//                                                         .,,,,(%#/((%@@@(,..            //
//                                   @/. &.*.&&&          .,(@@@(#,@/(@@@#*,..            //
//                          @@@#@@ @. &@. @   ...          .*&@&&%&//#@@(*,..             //
//                            ([email protected]@%@*@&*(   ........       .,%@#/*/(@@@@#,..              //
//         *  *   #*(#   ((*      (.#@% @@*@@.*/@...       ..*(((/(**%%*,,..              //
//         (,@@@(&/%* @,*@@@ &@@&&#.%*@@ %%/........       ...,,(%%***/&&/,               //
//         /@ *@#(@@@,. @                     ....            .............               //
//         #&.(&  @,@/ .*@@( &                                                            //
//         ( @@@@&%@. @ &[email protected]( @@ &@@ @,@&% @,                                              //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract NWO is ERC721Creator {
    constructor() ERC721Creator("Novus Ordo", "NWO") {}
}
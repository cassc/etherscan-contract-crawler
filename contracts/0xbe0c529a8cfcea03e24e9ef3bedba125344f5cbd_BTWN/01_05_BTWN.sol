// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everything In Between
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                @ .                    & %                                            @,@                     ,&                //
//               & @                   @ %&                                              #( @                   @ %               //
//              @ ,@                 @ #(                                                  %@ @                 *, @              //
//             *  #.               @  %@                                                    &&  @                (. %             //
//             ( /& .&           %.  %#                                                      */.  @           @, @@,,,            //
//            @ &@&& @          @  ,*.                                                         &%  &          % *(&%/%            //
//           # %@@. @          &  (&                                                            @@  /,         @( @&* @           //
//          ./ &@ %&         .( *@@                                                              @&  *,         @@ @@( *          //
//          @ &% ##          ( &@@                                                                @@/  #         && ,@ &          //
//         @ /.  *.        ,, #&&                                                                  &@@ .#         #.  % @         //
//         /@  %.,        /. (@(                                                                    #@@  #         %#  @./        //
//        &#  %&*        ** *@ /                                                                    **@&  &        [email protected]@  ,@        //
//       /,  //(        *, [email protected] @                                                                      # @#  &        ,#&   (       //
//      .(  .,@        /   @@@                                                                        @[email protected]/  #        @,*  *       //
//      @    #@       (. *@@%                                                                          &&@,  #       &@    @      //
//     *     @@      *, *@@./                                                                          .(@@,  %      (@     &     //
//     @,    @%     ./  #@#@                                                                            (,@@*  (     (@     @     //
//     (,  . @&     &  &[email protected]&                                                                              @&%@  (     (@ *  %.*    //
//    ([email protected]  ( @@    &    ,,*      %.                    %*                  #@                    .*,      (@ /  &    #@ %  @##    //
//    @** ,@ /@    @  //&@      & (                  ,*(.                   ( #                  #,@      &(..  @    @@ @. .&&    //
//    %.%*%@  %&   @   ..#     @ #/                 & &@                    #% @                 .,.&     /     (   *@  @@/ &%    //
//     (@/@@%  #/  (  , ./   .(  @                 /. *,                     #  #                 &  ,/    ( /  ,*  @  [email protected]@&@,*    //
//     @#@@@@.   #,.  @@*   *. *@                  @  &                      @  &                  @,  &   &@@  .//    @@@@@@     //
//      @@@@@@,   , &@@@@   @  ,                  ,/  @                      @  .*                  #. %   @@@@@ /    @@@@@&      //
//       @(@*@ @  .  @@@@   @ ./                  @  ,@                      @.  @                  %. *   @@@@* ,  (,& @%@       //
//         @/@,  ,  * [email protected]*.  @ & %                 %   ,*                     ( . (.                ,*@ *   &@, &   .  @@&.        //
//           @[email protected]#     (  &  @(@%@                #  / ,#                    (( #  &                @*@@., @. #     /@[email protected]           //
//             .&(@/ /  ,. @ @@@@.               / #@ @.                     @ // ./               @@@@ @. (  & ,@&%*             //
//                #%@@& @   .,@@@@              @[email protected](/ @                      @ ,%&[email protected]              &@@@*.   @ (@@,&                //
//                   %/@@@*@,  &[email protected]&             # &&@ %                      (./@#.*,            #@//  [email protected]@@@/&                   //
//                      &#@@@@@#. & @%         /. #@(.#                       ,*@.. (         /@ % #/@@@@@,&                      //
//              @@@@@@@@@&,#(&@@@@@@. .   *%&@% & #@  #                      ,, @* @ #&&&(   .  @@@@@@@*&.%@@@@@@@@@              //
//             *@@,@@.    ,%&@@@@@@@@@@( ,#*&@@@@*@,@& @         ,,.        %,(@/@[email protected]@@@@//# /@@@@@@@@@@@%,     @@,@@%             //
//              @@@         .&.   [email protected]@@@@@@@@(*@@@@# @@@@@@@@%@@@@@%@@@@#@@@@@@@@,,@@@@((&@&@@@@@@*    %*         (@@              //
//               @@(           ,* .   *@#*@@@@@@@@.   .**%@* %.       # *@&**,    &@@@@@@@((@(   . .#           ,@@               //
//                #@%(           @#@/    @@@[email protected]@@@[email protected]@@@@@@@@@@@@@@&#@@@@@@@@@@@@@@@,%@@@*&@@.   [email protected]&%           ,@@&                //
//                  @@%         (@%/*    /%%@@@@@/    (@@@@@@@@@@@@@@@@@@@@@@(    ,@@@@@@(% .  */(@(.        *@@                  //
//                   *@@     %.  /@@@@@/  * @@@& .      *@@@@@@@@@@@@@@@@@@/      , @&@@/   ,@@@@@%  .(     @@(                   //
//                     ,@@.    &# %@@*%    @@,/#@@@@#@,  *@@@@@@@@@@@@@@@@(   @&@@@@%/,@@.   /*@@@ ,@.    &@(                     //
//                         (@@(         ../@@@ @&@@%%@@.%@@@@@@@@@@@@@@@@@@& @@@(@@@% @@@&..         ,@@%                         //
//                            .#@@*  ,  %@@@@@@(@        @@@@@&      %@@@@@/ .     @%&@@@@@&  .  ,@@%.                            //
//                                 */ * &@@@@@@@/ .     %@@@     @@     @@@@    * ,,@@@@@@@@ / ,(                                 //
//                                       .((&@@@@@@@  ,#@&    @@@@@@@@    #@@*  (@@@@@@&//*                                       //
//                                            @@@@@@@@@@@ &#%@&      (@@/@ @@@@@@@@@@@                                            //
//                                             &@ /@.   &@ @@ @@@@@@@@ &@ @@  . @. %@                                             //
//                                             @  ( (@  @@@ @@@@@@@@@@@@ @@@. @*,%  @                                             //
//                                            @ #@/@@@  @@%  @@@@@@@@@@. /@@* @@@&@& @                                            //
//                                           @ #@@@@@@@  @@@@%#(((((((%@@@@* @@@@@@@@ @                                           //
//                                          @ *@@@@@@@@@/ @@/          ,@@,[email protected]@@@@@@@@% @                                          //
//                                          @ @@@@@@@@@@@@@@@//&&##&&//&@@@@@@@@@@@@@@.(*                                         //
//                                         &[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @                                         //
//                                         @ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@.                                        //
//                                        /& @@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@ (&                                        //
//                                        @, @@@@@@@@  ./@@@@@@@@@@@@@@@@@@%   #@@@@@@@. @                                        //
//                                       [email protected]  @@@@@@@      @@@@@@@&(@@@@@@@ .    %@@@@@@/ @,                                       //
//                                       @(  @@@@@@      ,. &        . #,.#      @@@@@@*  @                                       //
//                                       @ @@@@@@@*                               @@@@@@@ @                                       //
//                                       @@@@@@@@@                                @@@@@@@@@*                                      //
//                                       @@@@@@@@&                                [email protected]@@@@@@@#                                      //
//                                       @@@@@@@@(                                [email protected]@@@@@@@#                                      //
//                                       [email protected]@@@@@@%.                              ,[email protected]@@@@@@,,                                      //
//                                        @@@@@@@@*                              /#@@@@@@@                                        //
//                                         @@@@@@@@@                            &@@@@@@@@,                                        //
//                                         #@@@@@@@@@@                        @@@@@@@@@@&                                         //
//                                          @@@@@@@@@@@&&                  /&@@@@@@@@@@@                                          //
//                                           @@@@@@@@@@@@@ @            & @@@@@@@@@@@@@                                           //
//                                            . @@@@@@@@@@@@@&        (@@@@@@@@@@@@@, ,                                           //
//                                               @@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@                                               //
//                                                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,                                                //
//                                                  (@@@@@@@@@@@@@@@@@@@@@@@@@@#                                                  //
//                                                    ,@@@@@@@@@@@@@@@@@@@@@@#                                                    //
//                                                       @@@@@@@@@@@@@@@@@@                                                       //
//                                                         ,@@@@@@@@@@@@/                                                         //
//                                                            #@@@@@@&                                                            //
//                                                              ,@@/                                                              //
//    Everything In Between By Brayden Hall                                                                                       //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTWN is ERC721Creator {
    constructor() ERC721Creator("Everything In Between", "BTWN") {}
}
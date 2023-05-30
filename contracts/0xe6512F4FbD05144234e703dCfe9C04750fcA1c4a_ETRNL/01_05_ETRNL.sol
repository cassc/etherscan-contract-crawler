// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ripples Through Time
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//              ..,*,,./,                                                                                           //
//         , ./((*/((##%##((//*         .                                                                           //
//        ///(#(     ,%%%%%   (%%%##((,                                                                             //
//       /(. #%//((/,,,#%#  /,       ,/###((*                                                                       //
//       .(#((#/     ,##%#%*,              (#/##(,.                                                                 //
//        , *,(#%#.      #%*                     .#%%#*            . ..                .**.,.          ..           //
//          ,**(  ####(,           ,#(*.            (%%%((  .   ..(       .    .,/(#####%%%(#%###((,.               //
//             /(#(,*(    *./(/             ###(..     #%&##/ .#%%/#.   **#%%#((#%* (  *#%%%%  *%%%%%/  (#(*,       //
//               ,/(##%#(*           .///.           .*#%&#%&&&&&&&((#%%(.            .*    %#%%&&&%((###%#  .*     //
//                *((//(      ./(.                 *(%L&O&V&E&@A&N&D&(,.                  *%%.*%%%%%   .%%((/(      //
//                   ((#%%#/              *(#%H%0%P%E#//%&S&[email protected]@[email protected]&G#      #,  .,(#///*.   ,%%%#   .#/  #%#./((    //
//                   .(/.(%%(      *#%%%%%###**.       /%[email protected]&E&R&N&AL#/      *,     (     (%#   .#.   .%%/ /%#/     //
//                     ,* *%%%%%%%%%#(.*               .&&&&&&&*   /%%#       /     ,#     /#    ,%/##(%%%((/       //
//                      *######(  ,/     .        /.  /%&&&&&/      .%%%*      /      #(    (%%%. /%%*(###/         //
//                     .((/(   *     ./       /, .   (%&&&&%.  .      #%%(      (      #%%(  #%%%(,(##*             //
//                      /###.     .*    ,/  .,  .   #%&&&%/   .*       #%%#      ##* .#%%%%#/.##/                   //
//                     .(###(  .*     /.   /   ,   #%&&&%/     /       (%%%%   *#%%%%  (##(,                        //
//                      /(((%%*     *    (.   *   *%&&%#   .  . (   *  .(%&&&%%#  #%%#.                             //
//                       (#%%#%#../     /    *    #%%%.   .  *  (*  /   ,.%&&%#%#, .                                //
//                        ((,#(%%/    *     (,   .##/    .  (   *   ,   *.%%#/(.**.                                 //
//                          .#%%# ,%%%.    /.    %%.   ,,  ,   .        #%#%%% *,                                   //
//                           /###,%%%%.,%%%%##.(##    /   .    *   ,%%#%&%# .//                                     //
//                              ,,####/##%%##(#,.*##/(   .,  .#%##%&%%%%&# , ..             ASCII art draws from    //
//                                           , /#/%%%# %%%, %%%%#%%&% . . .                   "Butterfly Effect"    //
//                                              *.#%###%%%#%%%(  /(/ .              by Carly McKinnis/@chuckit01    //
//                                                      ..                                                          //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//    Walks upon the sands of time                                                                                  //
//    Cast ripples from the shore                                                                                   //
//    Unknown what foreign lands they'll reach                                                                      //
//    Nor what they hold in store                                                                                   //
//                                                                                                                  //
//    Gossamer wings?  Tempest-born?                                                                                //
//    Lover's kiss, or raging scorn?                                                                                //
//    How do you tread?                                                                                             //
//                                                                                                                  //
//    When distant souls those ripples reach                                                                        //
//    and wash upon their being                                                                                     //
//    steps taken will be clear to all...                                                                           //
//    so how will you be seen?                                                                                      //
//                                                                                                                  //
//    Tinker? Tailor?                                                                                               //
//    Kindred, or Cruel?                                                                                            //
//    Artist? Martyr?                                                                                               //
//    Hopeless fool?                                                                                                //
//    Possibilities without end...                                                                                  //
//                                                                                                                  //
//    When ripples eyes no longer see                                                                               //
//    Their impact carries on                                                                                       //
//    With ebb and flow of memory                                                                                   //
//    Long after we have gone.                                                                                      //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETRNL is ERC721Creator {
    constructor() ERC721Creator("Ripples Through Time", "ETRNL") {}
}
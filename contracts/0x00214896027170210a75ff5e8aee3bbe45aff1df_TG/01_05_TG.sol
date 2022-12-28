// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Guild - by Phlick
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//     .========-:     ===.       -==-   ===.           ===.      :=+***+-.    :==-      -===.      //
//     [email protected]@@@@@@@@@%-  [email protected]@@:       %@@#  [email protected]@@:          [email protected]@@:   .*@@@@@@@@@@%-  *@@%    .#@@@-       //
//     [email protected]@@     [email protected]@@  [email protected]@@:       %@@#  [email protected]@@:                 :@@@%-.   :[email protected]+.  *@@%   [email protected]@@*         //
//     [email protected]@@:...:*@@@  [email protected]@@*+++++  %@@#  [email protected]@@:          .%%%:  %@@%  .+*:       *@@%  #@@@:          //
//     [email protected]@@@@@@@@@#.  [email protected]@@@%%%%%  %@@#  [email protected]@@:          [email protected]@@-  @@@#  :@@+       *@@%  :%@@*          //
//     [email protected]@@-:::::     [email protected]@@:       %@@#  [email protected]@@:          [email protected]@@-  [email protected]@@+      :*:   *@@%    *@@@-        //
//     [email protected]@@           [email protected]@@:       %@@#  [email protected]@@:  ******- [email protected]@@-   [email protected]@@@%**#@@@@=  *@@%     [email protected]@@*       //
//     -###           .###.       *##+  .###.  ######- .###:     -*#@@@@%*=.   =##*      .*##*.     //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract TG is ERC721Creator {
    constructor() ERC721Creator("The Guild - by Phlick", "TG") {}
}
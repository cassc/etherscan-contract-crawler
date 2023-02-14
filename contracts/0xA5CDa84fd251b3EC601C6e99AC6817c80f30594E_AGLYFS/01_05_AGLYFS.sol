// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alphaglyphs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                        .. .                            !Y5G5!:~YPG5?~.      !55YY:     ^!!!:           . ..                     //
//                     .5#Y&@GGP^..                      [email protected]#@#@@@@&BPG&@@&?     [email protected]@@.     [email protected]@B         ^[email protected]@5BY:.                 //
//                 ?Y!5:. [email protected]@5     Y:      ^!....         !GG&@@&:  ...^[email protected]@G    [email protected]@@      [email protected]@J     P7?Y.. [email protected]@^    :5               //
//                :@@@@&  &##@^  :[email protected]@&^     [email protected]&             [email protected]@@~  [email protected]@#^@@@:   [email protected]@@      [email protected]@J    [email protected]@@@5 ^@[email protected]&   ~&@&B             //
//                ~&@@@J P&  #@. JP&@B.     [email protected]&             [email protected]@@.5&B&@@B~&@@~   [email protected]@@[email protected]@Y    [email protected]@@&^ &5 ^@B :[email protected]&Y             //
//                 :7   [email protected]~^[email protected]&            [email protected]& .           [email protected]@@  :@&G. ^@@@.   [email protected]@@[email protected]@@?     7^   [email protected]!~^[email protected]   .               //
//                     ^@Y^^^^^@G           [email protected]&^^           [email protected]@@^.:7!^[email protected]@@7    [email protected]@&      [email protected]@?         [email protected]!^^^:[email protected]                  //
//                   .:&G ..   ^@P.:    ::: [email protected]@...::~P:     :@@@@@@@@@@@@G:     [email protected]@B      [email protected]@7      . [email protected]! ..   [email protected]! :               //
//               ^!!P&&&&&@@&&##&&#?!~^^?:^^B#GPBBBB#P:.:.::^PG&:..::::~^..::.:.!PPY      JGY7...^!7B&@&&&@@#&##&&G!!~^.           //
//              ~&@@@@@@@&&&@@#@@@@@@@@B:..                 [email protected]@@              .~#@@&^     [email protected]&&! [email protected]@@@@@@@#&&@&#@@@@@@@&5           //
//              ...::.....  . ...........                  .J55Y:              .....       .... ...::.....  . ..........           //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                 :^^::75G?P?~:::::                                                               //
//          ..:::^::^^^::::..^.                   :7&@@@J5B&&B&@@@#BJ ~5PGGJ~~YGBG57:      ^YPPP!     :!77^.      ....             //
//           :YPG~^~&@#Y7JYY^J                      .&@@P.!--&&@@B 77 @[email protected]&#@@@@[email protected]@@G.    ^@@@7     ^@@@.    ~B&&#&&&P^          //
//         :^!~Y#&@@&GG&@@&!:!:   .?^.:.             [email protected]@@Y !&&@@B75P~ :5P&&@@!   :.:[email protected]@@.   [email protected]@@~     ^@@#   .&@Y.    :[email protected]         //
//         7!7#[email protected]@GP&#!~5!  ~:~^  [email protected]@^          ^P!7 [email protected]@@Y [email protected]@GP#.~^    [email protected]@5 [email protected]@J   [email protected]@@~     :@@#   [email protected]@:       .          //
//        .    ^@@^:~.   #~ !G-Y  [email protected]@:           ?P::  [email protected]@@&@@B---J^:    #@@7~-----&[email protected]@P   [email protected]@@[email protected]@&    J&@&BBGPY~           //
//         #@&[email protected]@:  ^GGB&7 !GG^  ^@@:.          .   Y&[email protected]@@@G ?^. ^.    #@@~  [email protected]#^  &@@7   [email protected]@@&[email protected]@@#      .:^^^~7&@7         //
//         GPJ-#&@@7- -#[email protected]@! ^Y^   ^@@7^            ^?JY:[email protected]@B:  .  ~     #@@?::!7^[email protected]@@P    [email protected]@@:     [email protected]@#    :JP?     [email protected]@:        //
//         :~. [email protected]@@YB&P&@J:.~!^::.^@@!::::^5?      ?! !~^@@:^G##? ^     &@@@@@@@@@@@B~     [email protected]@@.     ^@@B   :@@7      [email protected]@.        //
//         ~!77&@BPB&&&#5:!?^!:-~^^J#G5GBBBBG~....::..:  [email protected]@:~7??^:~^.:::YP&!......^^..::.:.:5GP.     ^BYJ:.:!Y5~:    ~5Y~..       //
//         !P#---5G&#&&5~J~JGJ?7Y.                     .?JG&&P?5~.....   :@@@!              ^[email protected]@@Y     [email protected]&&5.  .JB#B##&&Y.         //
//           .                 :                              ..        !YYY~              .....       ..         .::.             //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AGLYFS is ERC1155Creator {
    constructor() ERC1155Creator("Alphaglyphs", "AGLYFS") {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Tried to Unkill Myself
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                      .7777777777!^.        .^!7?J?7~:                                                                                          //
//                                                                                      [email protected]@@@@@@@@@@@#5^    :P&@@@@@@@@&G!                                                                                        //
//                                                                                      [email protected]@@@@#B##@@@@@&~   [email protected]@@@#PPG&@@@@!                                                                                       //
//                                                                                      [email protected]@@@&~ ..!&@@@@7  ^&@@@#:   [email protected]@@@G                                                                                       //
//                                                                                      [email protected]@@@&^    [email protected]@@@!  ~&@@@P    ^&@@@#:                                                                                      //
//                                                                                      [email protected]@@@&~    [email protected]@@&~  [email protected]@@@P    ^&@@@&^                                                                                      //
//                                                                                      [email protected]@@@&^   [email protected]@@&:  [email protected]@@@P    :#@@@&^                                                                                      //
//                                                                                      [email protected]@@@@[email protected]@@&J   [email protected]@@@P    :#@@@&^                                                                                      //
//                                                                                      [email protected]@@@@@@@@@@@#!    [email protected]@@@P    :#@@@&^                                                                                      //
//                                                                                      [email protected]@@@@###&@@@@#7   [email protected]@@@P    [email protected]@@#:                                                                                      //
//                                                                                      [email protected]@@@&~ ..7&@@@@7  [email protected]@@@P    [email protected]@@#:                                                                                      //
//                                                                                      [email protected]@@@&^   [email protected]@@@?  [email protected]@@@G     [email protected]@@#:                                                                                      //
//                                                                                      [email protected]@@@&~   [email protected]@@@?  ~&@@@G.    [email protected]@@#:                                                                                      //
//                                                                                      [email protected]@@@&~   [email protected]@@@?  :#@@@&!...~#@@@P                                                                                       //
//                                                                                      [email protected]@@@&~    [email protected]@@@?   [email protected]@@@@&&&@@@@&~                                                                                       //
//                                                                                      [email protected]@@@&~    [email protected]@@@?    ?B&@@@@@@&#P^                                                                                        //
//                                                                                      .^^^^:.    :^^^^.     .:^^^^^^:.                                                                                          //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                 .::::. .:::                                                                                                    //
//                                                                                                 [email protected]&? Y&P7                                                                                                    //
//                                                                                                   .J&&PG~                                                                                                      //
//                                                                                                     [email protected]@B^                                                                                                      //
//                                                                                                   ~G5^7&@Y:                                                                                                    //
//                                                                                                 .?PG! :YGG5!.                                                                                                  //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                        ..:~~                        .:^!:                                                                                      //
//                                                     :^~~:.::                           7P&@B.                      ^Y#@@!                                                                                      //
//                                                  [email protected]                     ^      ^@@B.                        [email protected]@!                                                                                      //
//                                                 [email protected]     ^GP         .         ^PG      ^@@B                ..       [email protected]@~                         JPJ.   .                                                     //
//                                                 :&@&Y^.    ~     ~JY77J5J^   !5&@#JJJJ. ^@@B:!YGBGY:     ^JJ77Y5!.   [email protected]@7!YGBPJ^ .!JYYJ!: .!JY?^ [email protected]?77YGJ.                                                 //
//                                                  7#@@@#GY7:    ^[email protected]:   [email protected]@5. ^[email protected]@B~^^^. ^@@[email protected]@#:  :[email protected]  :[email protected]:  [email protected]@?^^~?#@@J  ~&@&~   :#Y. ?P^ :[email protected]!  .?B:                                                 //
//                                                   .!YG#@@@&5: [email protected]@~     [email protected]@Y  :&@G      ^@@B     [email protected]@^ [email protected]&7!7775##?  [email protected]@~    :#@@!  [email protected]@B.  55   ~   :#@&P?~..                                                  //
//                                                 ^:    .^[email protected]@5 ^&@&^     [email protected]@P  ^&@G      ^@@B.    [email protected]&^ [email protected]@#^........  [email protected]@!     [email protected]@7   [email protected]@5 7P.        .?P#@@&P^                                                 //
//                                                 J#~      ^@@? [email protected]@7     [email protected]@!  ^@@B      ^@@G     [email protected]&^ [email protected]@J          [email protected]@~    .#@G.    [email protected]@5P:        ~7  .:7#@G                                                 //
//                                                 [email protected]&5!:::~5B7   :5&#7:.:J&G~   :#@@[email protected]@#^   ^#@@!. :5&@GJ?7??7:  [email protected]@Y^::^5#J.      [email protected]#^         [email protected]~:.:P#~                                                 //
//                                                 :7^!??777~.      :!?7!77^      :7?J7~: ^!!!!~. .~!!!!^   :!?YY?!^    ^!?JJ?7!^.        :#~          .!?J777~.                                                  //
//                                                                                                                                   ^JY!~P!                                                                      //
//                                                                                                                                   7#&#5^                                                                       //
//                                                                                                                                    .:.                                                                         //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RO is ERC721Creator {
    constructor() ERC721Creator("I Tried to Unkill Myself", "RO") {}
}
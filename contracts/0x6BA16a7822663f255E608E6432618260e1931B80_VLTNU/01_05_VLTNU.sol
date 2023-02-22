// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Valentino & UNXD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//        :::::..       .::.   .          ..:::::.        .:::::.....:^^:  ..:::.      .:::  ::^::.::::.:^::  ..::::.  .:^::       .::.      .:^^^:             //
//        [email protected]@7        ^Y..   #G         [email protected]@~.           [email protected]@P .....~#&.  .P#@&7      ^?. .&&5^..#@&:..7&@^ [email protected]&:.   ~G&@#.     .J^.    75~.  .^YJ.          //
//          :&@#        ?.    [email protected]@!          [email protected]@:            [email protected]@Y        G.   [email protected]@J     .!  .&^    [email protected]&.   .B^   [email protected]&.    :^~&@&:     7.   :##.       P&~         //
//           [email protected]@P      :7    .?#@&.         [email protected]@:            [email protected]@Y    .   .    ?  [email protected]@5    .!  .!     [email protected]&.    ::   [email protected]&.    ^~ ^&@&~    7.  :&@^        .&@!        //
//            [email protected]@!     J     ? ^@@5         [email protected]@:            [email protected]@Y   .G.       ?   [email protected]@G   .!         [email protected]&.         [email protected]&.    ^~  .#@&!   7.  #@#          [email protected]&.       //
//            .&@&.   !^    ~^  [email protected]@^        [email protected]@:            [email protected]@P.:?&&        ?    [email protected]@B. .!         [email protected]&.         [email protected]&.    ^~   [email protected]@?  7. :@@G          [email protected]@!       //
//             [email protected]@B  .J    .?   .&@#        [email protected]@:            [email protected]@5 .:5&        ?     [email protected]@#..!         [email protected]&.         [email protected]&.    ^~     [email protected]@Y 7. ^@@G          [email protected]@7       //
//              [email protected]@J ?.    J~.::[email protected]@Y       [email protected]@:            [email protected]@Y    Y.       ?      ~&@#7!         [email protected]&.         [email protected]&.    ^~      [email protected]@5J. .&@B          [email protected]&:       //
//               #@&J!    ^!      [email protected]&:      [email protected]@:        ?^  [email protected]@Y         ?.  ?       ^&@@!         [email protected]&.         [email protected]&.    ^~       [email protected]@&.  [email protected]&.        .&@?        //
//               :&@#     J       .&@B      [email protected]@:       ^&:  [email protected]@Y        !&.  ?        .#@!         [email protected]&.         [email protected]&.    :~        [email protected]&.   [email protected]        5&7         //
//                [email protected]^    ?~        [email protected]@J     [email protected]@^   [email protected]@:  [email protected]@P ....:[email protected]&. .Y.        .#7         #@&:        [email protected]&:    ~!         !&.    .5J.    .JY.          //
//                 !   ..:..      ..:::.. ..:::.....:^^:: ..:^^::::::^~^^^ ..:..        .:       ..^^^:.      ..:::..  .::.         :        :::::.             //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                           :?!~^:                                                                             //
//                                                                         :#@~   :?                                                                            //
//                                                                         &@&     ?                                                                            //
//                                                                         @@@Y   :.                                                                            //
//                                                                         [email protected]@@Y..   :~?55?^.                                                                   //
//                                                                        :[email protected]@@P       BG                                                                      //
//                                                                     .Y?:  [email protected]@@B      ~^                                                                      //
//                                                                    [email protected]     [email protected]@@#.    ^^                                                                      //
//                                                                   [email protected]@       [email protected]@@&.   ~.                                                                      //
//                                                                  ^@@@:       :@@@@^  !                                                                       //
//                                                                  :@@@#        .&@@@!~                                                                        //
//                                                                   [email protected]@@G        .#@@@?    .                                                                   //
//                                                                    7&@@&~       [email protected]@@P. .7                                                                   //
//                                                                      ~5#&#J^:...  ~B&@&P!                                                                    //
//                                                                           ..                                                                                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                             5##B           ?##G      .###G^           B##~      J&##Y        ?###J      J###&&&&&&&##BP7.                                    //
//                             #@@@           [email protected]@&      [email protected]@@@@B^        [email protected]@@7       [email protected]@@&!    ~&@@&!       [email protected]@@#BBBBBB#&@@@@#^                                  //
//                             #@@@           [email protected]@&      [email protected]@@@@@@#~      [email protected]@@7        [email protected]@@[email protected]@@J         [email protected]@@.         ~&@@@!                                 //
//                             #@@@           [email protected]@&      [email protected]@@[email protected]@@@&!    [email protected]@@7          ~&@@@@@@G.          [email protected]@@.          .&@@@.                                //
//                             #@@@           [email protected]@&      [email protected]@@~ [email protected]@@@&7  [email protected]@@7            #@@@@J            [email protected]@@.           [email protected]@@^                                //
//                             #@@@           [email protected]@&      [email protected]@@!   [email protected]@@@&[email protected]@@7          [email protected]@@@@@Y           [email protected]@@.           [email protected]@@:                                //
//                             [email protected]@@^          [email protected]@&      [email protected]@@!     [email protected]@@@&@@@7         [email protected]@@B:[email protected]@@&~         [email protected]@@.          [email protected]@@G                                 //
//                             [email protected]@@@5~:....^?#@@@?      [email protected]@@!        ?&@@@@@7       ^#@@&!   :[email protected]@@G.       [email protected]@@!::::::^!Y&@@@G       7BB!                       //
//                              ^[email protected]@@@@@@@@@@@@B~       [email protected]@@!          ?&@@@7     [email protected]@@5       !&@@@J      [email protected]@@@@@@@@@@@@@&P^       [email protected]@@&                       //
//                                 .^!77777!~:           ~~~.            ^~~.     :~~~:         .~~~~.     :~~~~~~~~~~^^:.           .77.                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VLTNU is ERC721Creator {
    constructor() ERC721Creator("Valentino & UNXD", "VLTNU") {}
}
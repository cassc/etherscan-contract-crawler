// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Konstant FLUX
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                    [email protected]@@P.                                                                 //
//                    :7?!.           ^@@@@@!  [email protected]@@P.                                                        //
//                   ^&@@@G.          .#@@@@?  :&@@@@7                                                        //
//                   :&@@@@J           [email protected]@@@Y   [email protected]@@@B.                                                       //
//                    [email protected]@@@@^          [email protected]@@@P   [email protected]@@@Y                                                       //
//                    .#@@@@B.        [email protected]@@@#.   [email protected]@@@@7                       .^!!.                          //
//                     [email protected]@@@@P        :&@@@@@^    [email protected]@@@@7             .:^!7J5PB##B&&!                         //
//               ~77~^:[email protected]@@@@Y       ^@@@@@@?     [email protected]@@@@?..:^~!7JY5PGBBGP5Y?7~:. [email protected]                         //
//              [email protected]@&&&&#&@@@@@@[email protected]@@@@@B?JJYYY#@@@@@#PPP5YJ?7!~^..         :&@7                         //
//              [email protected]:^[email protected]@@@@@@G5PPP#@@@@@@@P777!~^7&@@@@5                     [email protected]@!                         //
//              [email protected]      .#@@@@@@#!   [email protected]@@@@@@P       ~&@@@@Y                    [email protected]@~                         //
//              [email protected]       [email protected]@@@@@@@G7~&@@@@@@@@~       ~&@@@@7                   [email protected]@^                         //
//              [email protected]        [email protected]@@@@@@@@@@@@@@@@@@P        [email protected]@@@B.                  [email protected]@: .~!.                    //
//             [email protected]#7.      :&@@@@##@@@@@@[email protected]@@G        ^@@@@&: !??^             [email protected]&: [email protected]@B.                   //
//           :[email protected]@@@@?       [email protected]@@@#^~?YYJ~  .7J7.        [email protected]@@@# [email protected]@@@7            [email protected]&: [email protected]@@^                   //
//          ^#@@@@@P:        [email protected]@@@5                    ~&@@@@? [email protected]@@@&^           [email protected]&: [email protected]@@~ :YP5^             //
//         [email protected]@@@@#.         ^@@@@@!                  7&@@@@5   [email protected]@@@G           [email protected]&: [email protected]@@! [email protected]@@P             //
//         [email protected]@@@[email protected]:          [email protected]@@@B.               ^[email protected]@@@@J    :&@@@@!          [email protected]@^ [email protected]@@! [email protected]@@5             //
//        :&@@@@[email protected]^           [email protected]@@@Y~!?JJJYJJ?7~ :Y&@@@@B~      [email protected]@@@G          [email protected]@^ ^@@@! [email protected]@@Y             //
//        [email protected]@@@# [email protected]~       .^[email protected]@@@@@@@@@@@@@@@@B#@@@@#?        :&@@@@^         [email protected]@^ :&@@7 [email protected]@@?             //
//        [email protected]@@@&^[email protected]^!?YPB&@@@@@@@@@@@&&#####&@@@@@@@&PYY5555YYJ?#@@@@5         ^@@! .#@@7 [email protected]@@?             //
//         [email protected]@@@&#@&&@@@@@@@@@@&[email protected]@@@@?:.... ~#@@@@@@@@@@@@@@@@@@@@@@@@@?        :&@!  [email protected]@7 [email protected]@@?             //
//         .J#@@@@@@@@@@&BPY?!^. [email protected]@@@G      [email protected]@@@@@&&###BBBBB###&@@@@@@G        .#@7  [email protected]@7 :&@@Y             //
//           [email protected]?7!^.  ?B#BJ..#@@@@!      !JJ!~^:...  :^^.  .:^~!?J7:         [email protected]  [email protected]@!  [email protected]@5             //
//               [email protected]      ^@@@@@[email protected]@@@J !PPY:  .:.     .5&@@#P~      ..          [email protected]   ~!.  ^BB!             //
//               [email protected]       ?#@@@@P !557 [email protected]@@@P.P&&#P!   [email protected]@@@@@7   ?#&&P!.       [email protected]                         //
//               [email protected]        ^&@@@@^     [email protected]@@@[email protected]@@@@B?:  :[email protected]@@@#.  [email protected]@@@@#G5?!^: [email protected]                         //
//               [email protected]         [email protected]@@@J     [email protected]@@@#. [email protected]@@@@&5~ .&@@@@^  :#@@@@@@@@@@&[email protected]&~                        //
//               [email protected]         [email protected]@@@P     ^@@@@&:   ^Y#@@@@@[email protected]@@@&:   [email protected]@@@@B#@@@@@@@@@B5!.                    //
//               [email protected]?         [email protected]@@@B     :&@@@@~     [email protected]@@@@@@@@5    .#@@@@7.^~?YG#@@@@@@#5^                  //
//               [email protected]?         [email protected]@@@B      [email protected]@@@7        [email protected]@@@@@&^     [email protected]@@@G       [email protected]#&@@@@@P^                //
//               [email protected]         [email protected]@@@B      [email protected]@@@Y          [email protected]@@@@@P^    ^@@@@@^      [email protected][email protected]@@@@Y.              //
//               [email protected]~         [email protected]@@@P      [email protected]@@@G         ~&@@@@@@@&?    [email protected]@@@J      [email protected]#  .?#@@@@B^             //
//               [email protected]^         [email protected]@@@J      [email protected]@@@#.       !&@@@@G&@@@@P:  [email protected]@@@G      :&@:   :[email protected]@@@&~            //
//              :&&:        .#@@@@!      :&@@@@^      [email protected]@@@@J ^[email protected]@@@#~ ^@@@@&:     .#@!     [email protected]@@@#:           //
//              [email protected]#.        [email protected]@@@&:      [email protected]@@@7     [email protected]@@@@J   [email protected]@@@@7 #@@@@!      [email protected]?      [email protected]@@@Y           //
//              [email protected]         [email protected]@@@P        [email protected]@@@Y    [email protected]@@@@?      [email protected]@@@@[email protected]@@@J      [email protected]      :&@@@G           //
//              [email protected]        .#@@@@!        [email protected]@@@G   [email protected]@@@@7        [email protected]@@@@#@@@@5      [email protected]      .#@@@?           //
//              [email protected]        [email protected]@@@B.        ^@@@@&^ [email protected]@@@@7          [email protected]@@@@@@@@5      [email protected]#.      !PP?            //
//             :&@^       :#@@@@7          [email protected]@@@J.#@@@@J            [email protected]@@@@@@@5      :&@^                      //
//             [email protected]        [email protected]@@@B^[email protected]@@@#[email protected]@@@G              [email protected]@@@@@@5       [email protected]                      //
//             [email protected]       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@PJJJJJJJJ????77!#@@@@@@5....   [email protected]                      //
//             [email protected]~   .:^[email protected]@@@@@@@@@&####&@@@@@@@@@@@@@Y^~~~~~~~!!!777??#@@@@@B5PPPP55G&?                      //
//            .#@7?Y55YJ&@@@@&GY7.       ~7YG#&[email protected]@@5                [email protected]@@@@7                                 //
//             ^??!^.   :J5Y!.                ..   ^~~.                 ^YP5!                                 //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KON is ERC721Creator {
    constructor() ERC721Creator("Konstant FLUX", "KON") {}
}
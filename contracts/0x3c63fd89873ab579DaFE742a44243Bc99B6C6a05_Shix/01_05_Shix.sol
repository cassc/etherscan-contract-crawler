// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shixart
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                 .::.                                                                           //
//                                                .Y##P!                         ^!!~^                                            //
//                                                ^#@@@G.                       :P&@&P:                                           //
//                                                ~&@@@P.                        :!??~                                            //
//                                                !&@@@P.                                                                         //
//                                                !&@@@5.                                                      ..                 //
//                               .::^^~~~~~^:     ~&@@@5                          ~YYY~    :7?:              .!PP?:               //
//                         .:~7JPGB#&&&&&&&&#7    ~&@@@5.                         [email protected]@@J  [email protected]@G7.           ^5&@@#!               //
//                      :~JP#&&&#BGPP55PPGB#&5.   ^#@@@P.     ..:::::::.          [email protected]@@5  .?#@@@&5~        [email protected]@@#?.               //
//                   .^YB&@&GJ!^:...    ...:~~    :[email protected]@@G..:!J5GBB#####BPJ~.       [email protected]@@P.   ^Y#@@@#J:     ^5&@@@P~                 //
//                  :Y#@@&Y~.                     :[email protected]@@#YP#&@@&&##&&&@@@@&G?:     [email protected]@@B:     ^Y#@@@G7. [email protected]@@B?.                  //
//                 [email protected]@@&?.                       [email protected]@@@@@@BY!~^^^^^[email protected]@@P:    [email protected]@@#:       ^Y#@@&G?5&@@&5^                    //
//                 [email protected]@@&7:::^^~~7?JY55PPP55J!:   [email protected]@@@@@5^            ~#@@@Y    [email protected]@@#^         ^5&@@@@@@&?.                     //
//                  :Y#@@&####&&&&&&&&&&@@@@@@B^  [email protected]@@@@P:             [email protected]@@G.   [email protected]@@&~          [email protected]@@@@@&5!.                    //
//                    ^75GBBGP5J?7!~~^~~?#@@@@P:   [email protected]@@@#~               [email protected]@@B:   [email protected]@@&7        [email protected]@@#Y5#@@&G?:                  //
//                       ....          ^Y&@@#Y:    [email protected]@@@P.               !&@@#^   [email protected]@@@?      .!G&@@#Y^  ^[email protected]@@B?:                //
//                                 .:75#@@BY^      [email protected]@@@?                ~&@@&~   [email protected]@@@J     ~5&@@&P~.     ^Y#@@@B7.              //
//                             .:!JP#&&B57:        [email protected]@@&~                ~&@@&7   [email protected]@@@Y   ^Y#@@&G!.         ~5&@@&G!             //
//                         :!?5G#&&#GJ!:          .5&&&B:                ~#@@@Y   7#&&#?  !B&@&G7.          .~?7P&@#J.            //
//                         ~G&#G5?~:.              ^~~~^                 .!JJ?^   .^~~^.  .^!7!.         .~JPY^ .~?~.             //
//                          :^:.                                                                      :~JGB5~.                    //
//                                                                                                 :!5B#P?^.                      //
//                                                                                             .^7PBBP?^.                         //
//                                                                                         .!7?PBB5!:.                            //
//                                                                                       .~P&&B5!:                                //
//                                                                                    .^JG&@BGBBJ.                                //
//                                                                                  .!5GPG#BJ?5Y~                                 //
//                                                                                 ^Y57: .::                                      //
//                                                                                ^?~.        :~~                                 //
//                                                                               !J:       :75PP!                                 //
//                                                                              7P:      :?PY~:.                                  //
//                                                                             ^#5:..^755PJ^                                      //
//                                                                             [email protected]&#GB#BJ7:                                        //
//                                                                         ..^7B&@@&#Y^                                           //
//                                                                    .J555BBBP?~!7~:                                             //
//                                                                    :B&G5?!^.        .                                          //
//                                                                    !BJ.        :!!~JG5:                                        //
//                                                                  :JB?.        ^P#GJ5G?.                                        //
//                                                                ^JBP~          .^^.  .                                          //
//                                                             :!5#B?.                                                            //
//                                                         .^75B&B?:                                                              //
//                                                    .:~?5G&&#P!:                                                                //
//                    ^YJ7~^:...            ...:^~!?YPG#&@&#P7^.                                                                  //
//                    :Y#&&&#BGPP555YYY555PPGBB#&&@@@@&BPJ~:                                                                      //
//                      ^7YGB&&@@@@@@@@@@@@@@@@&#BG5J!^:.                                                                         //
//                         .:^~!??J5555555YJ?7!~^:.                                                                               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Shix is ERC1155Creator {
    constructor() ERC1155Creator("Shixart", "Shix") {}
}
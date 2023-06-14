// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Transient Reveries
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//    வழிப்போக்கன்                                                                                                                                               //
//    ██╗   ██╗ █████╗ ██╗     ██╗██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███╗   ██╗                                                                  //
//    ██║   ██║██╔══██╗██║     ██║██╔══██╗██╔═══██╗██║ ██╔╝██║ ██╔╝██╔══██╗████╗  ██║████╗  ██║                                                                  //
//    ██║   ██║███████║██║     ██║██████╔╝██║   ██║█████╔╝ █████╔╝ ███████║██╔██╗ ██║██╔██╗ ██║                                                                  //
//    ╚██╗ ██╔╝██╔══██║██║     ██║██╔═══╝ ██║   ██║██╔═██╗ ██╔═██╗ ██╔══██║██║╚██╗██║██║╚██╗██║                                                                  //
//     ╚████╔╝ ██║  ██║███████╗██║██║     ╚██████╔╝██║  ██╗██║  ██╗██║  ██║██║ ╚████║██║ ╚████║                                                                  //
//      ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝                                                                  //
//       NaN                                                                               நான்                                                                  //
//                                                                                                                                                               //
//                                                             ..                                                                                                //
//                                                  .~7JYPPJY#@Y                                                                                                 //
//                                                  [email protected]@@@@@  @J                                                                                                  //
//                                                   [email protected]@@@@::@                                                                                                   //
//                                                    [email protected]@@@75Y                                                                                                   //
//                                                    [email protected]@@@#P      .:?5:                                                                                         //
//                             :7?YG&BJ~:.             [email protected]@&B: ..^P#B&&^                                                                                          //
//                                ..^?#@#GBBGPY?!^..   7&P&[email protected][email protected]~~J                                                                                           //
//                                ^JP5!.   .~#BB&@@&&#B&@@@5?G#   #^!!                                                                                           //
//                             ~PGJ^         ^[email protected]@@@@@&@#&&&@&!:.557^                                                                                           //
//                         .7G#5^          .~~#@[email protected]@@7.^G##@&#J^[email protected]&7                                                                                           //
//                     .7P#BJ:     .^!JG&BGB&B:     &@@@!:[email protected]@@GP.                                                                                         //
//                      ~!::?!?5#&BB&@@B55!::.      [email protected]@&  7B!#   [email protected]!~^::.:7.                                                                               //
//                          ....YY7!~^.             ^@@5  .P7P     [email protected]  ^[email protected]&@@&G&                                                                                //
//                             :~.                  :@@?   5J?     [email protected]:   @@&5#@@&                                                                                //
//                                                  [email protected]@!   PP!      @~   [email protected]@B&@@#                                                                                //
//                                                  [email protected]~  .B&^      @!   [email protected]@7&@@B                                                                                //
//                                                  &@J^  [email protected]@:     [email protected]!    @@[email protected]@@G                                                                                //
//                                                .5G&?J :@@@.     [email protected]~   [email protected]&GBBY?                                                                                //
//                                               ^@^.&[email protected]@B&   .  :@^    #@J7:                                                                                  //
//                                             ^[email protected]@7~!   @@@#   .  [email protected]     ^                                                                                     //
//                                             77#&^     @@@~      [email protected]                                                                                            //
//                                               P&YJ?5:[email protected]@:       J#                                                                                            //
//                                              .&#[email protected][email protected]&&        JG                                                                                            //
//                                              :@#J5G^[email protected]@@7       :?                                                                                            //
//                                              [email protected]#Y~# [email protected]@7                                                                                                     //
//                                              [email protected]&5J& [email protected]@7                                                                                                     //
//                                              [email protected]@[email protected] @@@?                                                                                                     //
//                                              [email protected]@#[email protected] #@@?                                                                                                     //
//                                              [email protected]@@@@?:[email protected]@7                                                                                                     //
//                                              [email protected]@P^B. ^@G.                                                                                                     //
//                                              &@@.    [email protected]^                                                                                                     //
//                                              G&@    [email protected]?                                                                                                     //
//                                             :P&@Y^:[email protected]:                                                                                                     //
//                                              ^&@^     @?                                                                                                      //
//                                               [email protected]  [email protected]                                                                                                      //
//                                               :G.   !&@Y                                                                                                      //
//                                        :~!7JY5PJ^     5:                                                                                                      //
//                                        ~7~^:.                                                                                                                 //
//                                                                                                                                                               //
//    The collection i minted on opensea at first (2021), but i dont wanna use opensewer after they denied royalties to artists,                                 //
//    so am reminting them as better erc721 standard                                                                                                             //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WAY4R21 is ERC721Creator {
    constructor() ERC721Creator("Transient Reveries", "WAY4R21") {}
}
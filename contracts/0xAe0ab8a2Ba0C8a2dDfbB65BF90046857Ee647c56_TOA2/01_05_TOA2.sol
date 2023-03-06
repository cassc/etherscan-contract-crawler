// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Old Apartment Pt 2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                           ...............                                                              //
//                                                     :^^^::.....      ...:^!777^.                                                       //
//                                                 .:^:.                        .^7?7:                                                    //
//                                              .^~:                                .~?!.                                                 //
//                                            :?~.                                     .!!                                                //
//                                          .57                                          .7~                                              //
//                                         ~B:                                    .:       ??                                             //
//                                        ^B       .^~~:      :7JJ7:              ~7        JJ                                            //
//                                       .B.      5P&&&&J    5#&@@&@7              J         ?J                                           //
//                                       Y:      [email protected]@@@@@&   [email protected]@@@@@@#              J!         !7                                          //
//                                      !7       [email protected]@@@@@?   [email protected]@@@@@@Y               G.         ?7                                         //
//                                     .J        .#@@@@J     ^&@@@&?                :P          Y~                                        //
//                                     5^     ^:   ~YJ.        .^:                   5^          G.                                       //
//                                    ^Y      ~7  ^:                                 .P          :B                                       //
//                                    #~      ^P. ..                                  5^     ..   ?Y                                      //
//                                   J&^      5Y  ~:                                  :P         . 5:                                     //
//                                  [email protected]#.     ~&.  P^                           :^      P:          YG                                     //
//                                  [email protected]&^     ?B  ^B~                           .~.     :5          :#.                                    //
//                                 ^@&&~     J# [email protected]                           .!       P:         .5Y                                    //
//                                 #P#@?     !&!:#@&^                          :P       :P          :#                                    //
//                                7B:[email protected]     [email protected] [email protected]@J                          .P:       5:          &!                                   //
//                                #[email protected]#     G&. .#@?                           5!       ^P         .PB                                   //
//                               J!  :#@.    B#   J&.                          .5~        #:        [email protected]                                  //
//                              .5    [email protected]~   :@B   75                            ~!        7P         :&?                                  //
//                              J.     PJ   [email protected]#:  P:                            ?Y         #:        .G&                                  //
//                             :7      Y7   .&#. .G                             ~P         5Y         ^@:                                 //
//                             J.      P~   [email protected]#. !Y                             .B         :&.        .GY                                 //
//                            ^!     . G.   [email protected] P:                             :B         .BY        .5#                                 //
//                            P:      ^5    [email protected]#:.P                               B.         !&.        ^&:                                //
//                           ^P       5^   .#@B.!?                               G.         ^&?        ~#?                                //
//                           P7      .P    .#@&^5:                               G.         .B&         GB                                //
//                          .#.  . . P!    :&@&!G              .                 P.          [email protected]!       [email protected]                                //
//                          YG  ...~7G     [email protected]@B7P              .                 G.         . P#       :[email protected]~                               //
//                          #? ... ^#:    :#@@&B?                              .:B           [email protected]:      :[email protected]                               //
//                         :&:. ..:!G     [email protected]@@@@.               .              :5B           .~&G      [email protected]&                               //
//                         J5 ..:^YB.    [email protected]@@BG                  .~.           ?G            Y#@.     ^#@@^                              //
//                         G^:  :.5?      #@@@@J                 .:7.           ^P            ^P&J    .7&@@5                              //
//                        .#:.:!^7P     :!&@@@@.                  .^!~.         ~Y           .:JB&    .^5&@@:                             //
//                        7P...~J&.     :#@@@@&                    .P&J!:.      !5           [email protected]^    :~&@@B                             //
//                        BY.:~J&!     [email protected]@@@@5                    .^5BBGY?.    ^&.           .Y#@G     :[email protected]@G?                            //
//                       .&Y~^^GG      [email protected]@@@@@:           .    .     !PGBB#B?.. :&^          . .5#@.    ^B#@G#                            //
//                       !P^:7?&.      [email protected]@@@@#                       .~7J&&&&5!!^&P          .!^P&@!    .Y&@5&7                           //
//                       GY^~:G^      Y&@@@@@7                         ^7JJPB#[email protected]         .~!5&@B     J#@PY#                           //
//                       &7 :?5      7&@@@@@@^             .             .^!7YP5Y&&J         .7~P&@@. ..^Y^B&[email protected]!                          //
//                      ^@?.^G.     ?G&@@@@@B           .                ..^. ^GY&@5         .!PB&&@J   .!:#@[email protected]^                         //
//                      Y&^:G:     [email protected]@@@@@@!         :.^.:...             .::.^[email protected]@G         .!G#5#@B   [email protected]&[email protected]!                        //
//                      &#.57      !B&@@@@@&.        .....!^:^.!~ ..       ..:.^?#@&.        .~&@@&@@.  [email protected]@J5J&Y                       //
//                     .&~?Y      :Y&@@@@@@5         :.~^7~!?YY:^.:~.     . .:.7^[email protected]&.        [email protected]@@@@!...!Y?#@Y^:YBG.                     //
//                     7#?#      ^[email protected]@@@@@@@.      .:.~7?5G!7?YYY~?~^.        ... .&B        .:!&@@@&@5 . ^[email protected]#^7GG&&:                    //
//                     #&&^     .7&@@@@@@@&.      ..7~^P?BY!5JYY7!:::...   .    :.G#         [email protected]@@@&@& ...^?&@@77YG#&@~                   //
//                     &@!     .!#@@@@@@@@^     ..^^~!??Y5BJ5?#G?^?7^:.       . ..PB         [email protected]&&@@@@:  .:?B&@?!JPB#[email protected]                  //
//                     5!     .:[email protected]@@@@@@@#      ..^!7PY^?GJJ!B#57^5: ..  .. . .  .YG        [email protected]@@@@@@@5.. ^7Y&&#^[email protected]                 //
//                     ~^^.   [email protected]@@@@@@@@7      .:.:!??GJBYY?P7.Y::^. ... ..      ^P        [email protected]@@@@@@@&   .^5&@@!~~J?#B#B                 //
//                       .~!!!?#@&&#G5JJ&~     .^.::~^!YP5P?G!7:~~!. .  !!.:.     ~5        :&@@@@@&@@@:::.^77#@#?7P?Y?^                  //
//                             ..      5JG     : :.~!~7~G##&&B#B5J~~!~~~.:~.^~.^  !Y        ~&@@@@&@BB&5.  ^:J##@J:.                      //
//                                     7!Y!~~~!YJ77J!!7J7?77~~~!~~^~~!!^!B#G##[email protected]@@@@@@@&@#   ^~YJPB.                        //
//                                                                       ^!!JPGBB###&&&&@@@@@@@@@@@@&&&#!?7~^:.                           //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TOA2 is ERC721Creator {
    constructor() ERC721Creator("The Old Apartment Pt 2", "TOA2") {}
}
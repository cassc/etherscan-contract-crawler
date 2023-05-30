// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One eyed guys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                              ::..                                                                                                                            //
//                          .~?J!~~!7???77!~^:..                                                                                                                //
//                       :!J?^           ..:^~!777?Y5?.                                                                                                         //
//                     .#BP?!!!!~^::..          :[email protected]@@B~YJ????77~^:.                                                                                            //
//                     ~B    ...::^~!7????7775#@@@@@@#J:        :?&@G      ::..                                                                                 //
//                     !G                   [email protected]@@@@@55?!~^:.   ^5&@@@@&. .75!~!7????77^                                                                          //
//                     7G                   :@@@@@&   ..:~!??&@@@@@@@@@5J:        [email protected]@: ^YJ????7!~~^^::....                                                     //
//                     7B                   :@@@@@&          ^@@@@@@@@@577!^.   :[email protected]@@@PJ!.     ...::^~~!!77?????777~                                            //
//                     ~#      .!^:.        :@@@@@@           [email protected]@@@@@@#  .:^[email protected]@@@@&P~::::...                :[email protected]@^                                           //
//                     ^#      [email protected]@@@@@#     [email protected]@@@@@.           [email protected]@@@@@#        [email protected]@@@B ..:^^~!!!7?????7!~^:.:?B&@@@@@~                                           //
//                     ^#      [email protected]@@@@@@.    [email protected]@@@@@.            [email protected]@@@@&        [email protected]@@@&                ..:^[email protected]@@@@@@@@!       .!P#&@@&BY^                         //
//                     :&      [email protected]@@@@@@.    [email protected]@@@@@:             [email protected]@@@&        [email protected]@@@@.                     &@@@@@@@@!     :[email protected]@@@@@@@@@@&J                       //
//                     :&      [email protected]@@@@@@:     @@@@@@^              #@@@@        [email protected]@@@@.                     &@@@@@@&5.    P#[email protected]@@@@@@@@@@@@&^                     //
//                     :&      [email protected]@@@@@@^     &@@@@@~               &@@@:       #@@@@@^        .GGPJ7!~^:[email protected]@@@#?.     .&P  :7#@@@@@@@@@@@@?                    //
//                     :&      [email protected]@@&[email protected]:     &@@@@@!        .^     .&@@~       &@@@@@~        [email protected]@@@@@@@&BGG###57!YGJ   &5      [email protected]@@@@@@@@@@@~                   //
//                     :&      ^##G?~^&.     [email protected]@@@@7        [email protected]~     .&@7       &@@@@@!        [email protected]@@@#Y~.       [email protected]@@. G#       [email protected]@@@@@@@@@@@@                   //
//                     :&          ..:.      [email protected]@@@@J        [email protected]@^     [email protected]       @@@@@@7        ^&&BY?7777?77?G&@@@@@@.:@:       &@@@@@@@@@@@@@J                  //
//                     :&                    [email protected]@@@@Y        [email protected]@@.     :!       @@@@@@?                    [email protected]@@@@@@@@.P#  :~..~#@@@@@@@@@@@@@@&                  //
//                     :&                    :@@@@@P        [email protected]@@&.             &@@@@@?                    :@@@@@@@@P &?  [email protected]@@@@@@@@@@@@@@@@@@@.                 //
//                     .#7~^..               [email protected]@@@@P        [email protected]@@@#             &@@@@@?        :5J7~^:..   [email protected]@@@&P!.  @~  :@@@@@@@@@@@@@@@@@@@@.                 //
//                       ..:~?P#P?7!~^:.      @@@@@P        [email protected]@@@@G            &@@@@@?        [email protected]@@@@@@@@B5PP?:       @!   #@@@@@@@@@@@@@@@@@@@                  //
//                        .^7?!:   .:^[email protected]@B!5G        ^@@@@@@J           &@@@@@J        ^@@@@@@&P!^~!!77777?J7 #5   ^@@@@@@@@@@@@@@@@@@#                  //
//                     .P#P7.                ..:^~YP7~:.    ^@@@@P^#:          &@@@@@Y        :@@@B7:         .~5&@@[email protected]    [email protected]@@@@@@@@@@@@@@@@?                  //
//                     !#.^~7???7~:.                .?&@[email protected]@P.  :#          &@@@@@Y          .:^!7????J?YG&@@@@@@! @7    [email protected]@@@@@@@@@@@@@@&                   //
//                     7G       .:~!????!~^..    ^[email protected]@@@P:JGJ:^~7??!BG..       &@@#^55                     &@@@@@@@@! [email protected]    :#@@@@@! [email protected]@@@@^                   //
//                     7G               .:^[email protected]@@@@@@&5~.        :[email protected]@[email protected]&!  YB::..                 [email protected]@@@@@@@^  Y&.     ^[email protected]@@^  [email protected]@@~                    //
//                     ?G                      #@@@@@@P?!^:.    ^5&@@@@P    .!PG!!7?JGGGB#B?????7!~^:..    [email protected]@@@&G?:    7&!       :!:   #&:                     //
//                     ?G                      &@@@@@@5 .:[email protected]@@@@@@@@^^7?!:        .?&@P    ..:^^~~!77?7GBJ^.         .GB!        .?B?                       //
//                     7P      ^&#GY?~:..      &@@@@@@@Y     .&@@@@@@@@@#B5!^...   ^Y#@@@P :!?J7!!77777!!~^:.              .?PPJ??J5GP!                         //
//                     7P      :@@@@@@@@#[email protected]@BY~.  PJ     [email protected]@@@@@@@J   .^~!77#@@@@@@@PY7:          ..:^~!7???77J7       ....::..                            //
//                     ?P       @@@@#5!.  ..^!?YJ?!~~^^^#7     ^@@@@@@^         [email protected]@@@@@~^~!7????7!~^:.          :[email protected]@^ .~5&@@@&#5!.                             //
//                     ?P       JBBY!^:.          .~5&@@PB!     [email protected]@@#.        ^&@@@@&?&         ..:^~!7????775#@@@@@@&&@@@@@@@@@@@@&5.                          //
//                     7G           .:^!7???7!!?G&@@@@@@P #^     [email protected]         [email protected]@@@@5  &                    ^@@@@@@@&7YPPB#@@@@@@@@@@@@B:                        //
//                     !B                    [email protected]@@@@@@@@G .&:     ^        :#@@@@&:  .&                    :@@@@@@@#       [email protected]@@@@@@@@@P.                      //
//                     ~#        ..           ^@@@@@@@@@P  :&.            [email protected]@@@@J    .&       !7^.         ^@@@@@@@&           7&@@@@@@@@@!                     //
//                     ^#        @@@&BPY7~:.  ^@@@@@&GJ!.   ?P          7&@@@@@&     .&      [email protected]@@@@&&#GPJ!^[email protected]@@&P!7#             ~&@@@@@@@@5                    //
//                     ^#       [email protected]@@@@@@&##&&#&@GJ^.        !P         [email protected]@@@@@@#     .&      :@@@@@@&#GY!::^~77!~~5#               [email protected]@@@@@@@G                   //
//                     ^#       [email protected]@@&G7.     .:^~!!777?7.   7P         @@@@@@@@G     .&      .G##G57^.          :?##                [email protected]@@@@@@@Y                  //
//                     :&        YBG?!~^::.       .~5&@@#   ?P        [email protected]@@@@@@@Y     :&           .:^!7????JYG&@@@@B      JP?^       #@@@@@@@@.                 //
//                     .&             .:^~7????5B&@@@@@@&   ?P        [email protected]@@@@@@@!     ^&                    [email protected]@@@@@@B      @@@@&:     ^@@@@@@@@J                 //
//                     .G?~^:.                 [email protected]@@@@@@@@   Y5        [email protected]@@@@@@@:     ~#                    [email protected]@@@@@@G      @@@@@&      &@@@@@@@G                 //
//                        .:^!JBG?~:.          [email protected]@@@@@@@&   YY        &@@@@@@@@.     7G      [email protected]&BGP5J!~:.. #@@@@&5GB      @@@@@@^     [email protected]@@@@@@5                 //
//                         .~??!:.:~!????7!~^:[email protected]@@@@@BJ~:  5J        @@@@@@@@@      Y5      [email protected]@@@@@@@&BJ775B#BY!:5B      @@@@@B      #@@@@@@@~                 //
//                      .5GY~.           ..:^~!J5!.  .^5&@B G7       [email protected]@@@@@@@#      PJ      [email protected]@@BJ!:           :!#G      &@@&?      [email protected]@@@@@@#                  //
//                      &?~~!7????7!!~^:..         ^Y&@@@@@.&5~^:..  :@@@@&5~.       G7       ..:~!7???7!~^::~JB&@@P      :^.        [email protected]@@@@@&.                  //
//                      &.         ..:^~!7?????J5#@@@@@@@@&J: .:^[email protected]@J.   [email protected]~                ..::[email protected]@@@@@@5                [email protected]@@@@@&.                   //
//                      &.                     [email protected]@@@@@@@&B7^:.    [email protected]@@~ .!J?^      ?BG5?~~^..            [email protected]@@@@@@Y               [email protected]@@@@@J                     //
//                      &.                     [email protected]@@@@@@P  .:^!7JP#@@@@@@#GP!.       [email protected]@@&PB7~777?YY7~^:.  [email protected]@@@@@@J             7&@@@@&?.                      //
//                     .&.                     [email protected]@@@@&&#        #@@@@@@@[email protected]@@@@#?.     [email protected]@&:^[email protected]@&5J5&P       [email protected]@@&P7.                         //
//                     .&       B&#GPYJ?!!~~^^:&@&G?: :&        [email protected]@@@@@@!        [email protected]@@@#[email protected]@@@@@!   ^??~.    ^&@&?77777?YPY7^.                             //
//                     .&       @@@@@@@@~.:!JPBB5?!!!!5&        [email protected]@@@@@@7        ^@@@@&      &@@@@@@@&JG&GJ~^:^!P&@@@^  ^!7?777777?????7!!7!~                   //
//                      &.      &@@@@@@@Y7?!^.       ^G&        &@@@@@@@!        :@@@@@P     ^@@@@@@@@5   [email protected]@@@@&:~5Y7^.            :J#@@@.                  //
//                      &.      &@@@@@@B?^.       ^Y&@@#        @@@@@@@@~        ^@@@@@@!     [email protected]@@@@@!      ^@@@@@G!&&Y7!77?????7!^^~5&@@@@@@:                  //
//                      &.      &@@@@. .:~!7???5#@@@@@@G       [email protected]@@@@@@@~        [email protected]@@@@@@.    :@@@@@^      [email protected]@@@@5JG:            [email protected]@@@@@@@@~                  //
//                      &:      &@@@&          ^@@@@@@@P       :@@@@@@@@^        [email protected]@@@@@@#     [email protected]@#.      [email protected]@@@@!55                [email protected]@@@@@@@&^                  //
//                      #~      &@@@@5?!^      :@@@@@@@J       ^@@@@@@@@^        [email protected]@@@@@@@5    .&B       [email protected]@@@&.^#        :75PPY7^.:@@@@&B?:                    //
//                      B!      #@@@@@@@@!     [email protected]@@@@@@~       [email protected]@@@@@@@:        [email protected]@@@@@@@@7           .#@@@@B  5Y        @@@@@@@@@@@&~.                        //
//                      G7      [email protected]@@@@@@@:     [email protected]@@@@@@:       [email protected]@@@@@@@:        &@@@@@@@@^#^         :&@@@@@.  ^#        .5&@@@@@@@@@P7:                       //
//                      G?      #@@@@@@@@      [email protected]@@@@@@        [email protected]@@@@@@@.        @@@@@@@@@ ~B        [email protected]@@@@@@.   ^P?:        [email protected]@@@@@@@&P.                    //
//                      G?      &@@@&5^:&      [email protected]@@@@@&        &@@@@@@@@.       [email protected]@@@@@@@& ~G        [email protected]@@@@@@.     :!?J?!:       [email protected]@@@@@@@@7                   //
//                      G7      [email protected]#J~:.~&      [email protected]@@@@@#        @@@@&P!:&        [email protected]@@@@@@@B ~B        [email protected]@@@@@@           :!5J       ^@@@@@@@@@:                  //
//                      B7        ..:^~!^      [email protected]@@@@@G       .#@#Y~:.:&        :@@@@@@@@Y !B        [email protected]@@@@@&              ^#.      [email protected]@@@@@@@?                  //
//                      #~                     [email protected]@@@@@P          ..:^~!!        ^@@@@@@@@! 7G        #@@@@@@&          .~J!^#G      [email protected]@@@@@@@^                  //
//                      BJ..                   [email protected]@@@@@5                         [email protected]@@@@@@@^ ?P        &@@@@@@&       :!J7^. ^#7      :@@@@@@@G                   //
//                      .^~!7???7!~^:...       [email protected]@@&YGP                         [email protected]@@@@@@@: J5        @@@@@@@&   ~?G#P7^:^!JY:       [email protected]@@@@@P                    //
//                               ..:^~!7?????7!Y&5^  7#..                       [email protected]@@@@@G~  5Y        @@@@@@@&  PP:^^^^~~^.         [email protected]@@@@#~                     //
//                                             .      ~~!!7?????77!~~^::..      ^@@&5^     G?        @@@@@@#!  G7                  &@@@G^                       //
//                                                               ..::^~~!77?????5P.        BY.      [email protected]@@&?.    B!                7&&P~                          //
//                                                                                         [email protected]^       GY...       ..:!JY7.                             //
//                                                                                                 .:           ^!!777777777!~:                                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OEG is ERC721Creator {
    constructor() ERC721Creator("One eyed guys", "OEG") {}
}
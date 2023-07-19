// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: billyrestey
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                      .^^       .!!. ^^.  :^:                                                                                  //
//                      [email protected]@:...   ^##:[email protected]@P  &@& ..      .     ..  .....     ....   [email protected]#.    .....  .      .                       //
//                      [email protected]@&#&@@^!&&&^[email protected]@P  &@& [email protected]@: .&@[email protected]@B&@[email protected]@#B&@&.!&@####G [email protected]@@&G [email protected]@#B&@#:[email protected]#  [email protected]@?                      //
//                      [email protected]@. :@@5 [email protected]@[email protected]@P  &@&  [email protected]& [email protected]@ [email protected]@Y.. [email protected]@[email protected]@[email protected]@BPGPJ  #@&   #@@[email protected]@[email protected]@G &@B                       //
//                      [email protected]@^[email protected]@5 [email protected]@[email protected]@B. &@@:  #@&@@^ [email protected]@!   [email protected]@[email protected]@P #@@:. #@@P555P. :@@&@&                        //
//                      Y&&&&&&G. ^&&^ Y&&# ~&&&^ [email protected]@@?  ^&&^   ^#&###BG 7#####&#^ ~#&&&!^#&###BG   [email protected]@@:                        //
//                                               #&@@J                                            :&&@&~                         //
//                                               ...                                               ...                           //
//                                                                                                                               //
//                      ~#BB################BBB.     .##5      J##5      ?##^      GBB################BB#7                       //
//                      [email protected]@@@&&&&&&&&&&&&&&&@@@:   ..~&@G   ...#@@&...   [email protected]@7     [email protected]@@@&&&&&&&&&&&&&&&@@@P                       //
//                      [email protected]@@.               &@@:  [email protected]@B      [email protected]@@@@@@@&   [email protected]@!     [email protected]@@.               &@@5                       //
//                      [email protected]@@   5GGGGGGGG7   &@@:  [email protected]@@[email protected]@@@@@&~~^   :~~YGG^  [email protected]@@   ~GGGGGGGGP   &@@5                       //
//                      [email protected]@@   @@@@@@@@@G   &@@:  ^@@@@@@@@@@@@@@@B         [email protected]@?  [email protected]@@   [email protected]@@@@@@@@.  &@@5                       //
//                      [email protected]@@   &@@@@@@@@G   &@@:     [email protected]@@@@@@@@!     [email protected]@@^  [email protected]@?  [email protected]@@   [email protected]@@@@@@@@.  &@@5                       //
//                      [email protected]@@   @@@@@@@@@G   &@@:  .55Y!!!777!!!.  [email protected]@@#55&@@?  [email protected]@@   [email protected]@@@@@@@@.  &@@5                       //
//                      [email protected]@@   B&&&&&&&&Y   &@@:  [email protected]@#..     ..   :@@@&&&@@@@&&!  [email protected]@@   7&&&&&&&&#.  &@@5                       //
//                      [email protected]@@                &@@:  [email protected]@@@@#   [email protected]@^  :@@&   [email protected]@!     [email protected]@@                &@@5                       //
//                      [email protected]@@[email protected]@@:  [email protected]@&??JYYYJJJJJJJJJJJJJJ??JYY:  [email protected]@@[email protected]@@P                       //
//                      [email protected]&&@@@@@@@@@@@@@@@@&&&.  [email protected]@#  ^@@@:  [email protected]@&  [email protected]@@7  [email protected]@7  .&&&@@@@@@@@@@@@@@@@&&@J                       //
//                                                [email protected]@@@@#      [email protected]@#  [email protected]@@@@@!                                                    //
//                      :?77??7   .??:      !?????J55555Y77?.  [email protected]@&[email protected]@@@@@G7?.   777??????:  .?????7                           //
//                      [email protected]@@@@@.  [email protected]@G     .#@@@@@P     :@@@!  [email protected]@@@@@@@@@@@@@@?  [email protected]@@@@@@@@J  [email protected]@@@@@:                          //
//                      [email protected]@@.  &@@@@@@@@@@@@:           :@@@@@@!  ^@@@@@@7  [email protected]@?   @@@.               #@@Y                       //
//                      :[email protected]@&7??Y5Y.  [email protected]@@P7?.   [email protected]@@~  :[email protected]@@             [email protected]@@P                       //
//                          @@@.     [email protected]@P   &@@:  [email protected]@@@@@@@@:        [email protected]@@!     [email protected]@@@@@             &@@@@@5                       //
//                      [email protected]@@@@@@@@@&&@@@G         [email protected]@#......   [email protected]&&&&[email protected]&&&&@@@@@@@   [email protected]@?                                    //
//                      ^[email protected]@@5YJ#@@@@@G   !J?JJJJJY!      ~JJ&@@@@@&   [email protected]@@@@@@@@@@@YJJJYYJJJ^   7J???J^                       //
//                          &@@   [email protected]@@@@G   &@@@@@G         [email protected]@@@@@@@&   [email protected]@@@@@@@@@@@@@@?  [email protected]@P   @@@@@@P                       //
//                          ...   [email protected]@@@@G   ...&@@@&&P  .&&&~..#@@&..^&&&7........^@@@@@@?  [email protected]@@&&#^.:&@@5                       //
//                      :77!   ~77J5555P!   ~!!&@@&PP?  :@@@5!!Y5P?  [email protected]@@~        [email protected]@@@@@B!7J55#@@@.  &@@P                       //
//                      [email protected]@@   @@@Y         &@@@@@G     :@@@@@@^     [email protected]@@~        [email protected]@@@@@@@@Y  [email protected]@@.  &@@P                       //
//                       ::^B##@@@@##7  :##B~.:&@@G  .##&@@@?..5####&G^::5##^      @@@^:[email protected]@J   :::B&#~:^.                       //
//                      .~^[email protected]@@BGG&@@#[email protected]@@?^~&@@#[email protected]@@GGG7^^#@@@GBY   [email protected]@[email protected]@@!^^[email protected]@G~~~~~~GBG                           //
//                      [email protected]@@@@@   [email protected]@@@@@@@@@@@@@@@@@@@@#   [email protected]@@@@#      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@                              //
//                       .....     [email protected]@@@@#   [email protected]@@@@@&&&&&&@@@@@@[email protected]@@@@G...   B&&J                       //
//                      .^:::^^^^^^:^^^^^^^^:::   [email protected]@@@@&^^^P#BBBBB#####[email protected]@@@@@?   :^:   [email protected]@@@@5   :^^@@@P                       //
//                      [email protected]@@@@@@@@@@@@@@@@@@@@@:  [email protected]@@@@@@@@^            [email protected]@@@@?  [email protected]@@   [email protected]@@@@5   &@@@@@5                       //
//                      [email protected]@@^.:..........:.:&@@:   ::[email protected]@@^        .#&&[email protected]@?   ...   [email protected]@@@@@&&#^.:@@@P                       //
//                      [email protected]@@   ..........   &@@:      ..~##&!.::::::[email protected]@@~  [email protected]@5.::...::[email protected]@@@@@&&#^.:B&&?                       //
//                      [email protected]@@   &@@@@@@@@G   &@@:     ^@@#   [email protected]@@@@@@@@@@@~  [email protected]@@@@@@@@@@@@@@@@@5   &@@.                          //
//                      [email protected]@@   &@@@@@@@@G   &@@:  :##P^^!BBB7::#@@&::[email protected]@@&##@@@@@@@~:[email protected]@@@@@@@@@BBB~^^                           //
//                      [email protected]@@   &@@@@@@@@G   &@@:  :BBJ  :@@@^  [email protected]@&^^[email protected]@@&BBBGGGGB5   @@@@@@&GG&@@@.  ^~~.                       //
//                      [email protected]@@   @@@@@@@@@G   &@@:        :@@@^  [email protected]@@@@@@@@~            @@@@@@Y  [email protected]@@.  &@@P                       //
//                      [email protected]@@   ^~^^^^^^~.   &@@:  :GGGBG#@@@#[email protected]@@@@@&~^^YGGGGGGBBBBBG~^^~~~JBBY~~~   ^~~.                       //
//                      [email protected]@@~::::::::::::::^&@@:  [email protected]@@######@@@@@@@@@&::.#@@@@@@#####B^::   ~&&?   :^::::.                       //
//                      [email protected]@@@@@@@@@@@@@@@@@@@@@:  [email protected]@#      [email protected]@@@@@@@@@@@@@@@@@?      @@@J         @@@@@@P                       //
//                      .7777777777777777777777   .77^      ^777777777777777777.      !77.         !77777:                       //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BR is ERC721Creator {
    constructor() ERC721Creator("billyrestey", "BR") {}
}